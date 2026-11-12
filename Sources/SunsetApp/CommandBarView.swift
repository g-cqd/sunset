import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// The command bar: a field and the rows under it, over the window's content (Cmd-L from anywhere in the app): the tabs that match (`TabSearch`), what
/// was typed as an address or a search, the engine's suggestions (`CommandBarRows`). The arrows move the keyboard's row, Return does its first action,
/// Cmd-Return its second, Option-Return its third, Cmd-K lists them all (`CommandBarActionsPanel`); Up in the empty field recalls earlier entries; an
/// engine's keyword and a space become a chip; Escape or a click outside closes it.
struct CommandBarView: View {
    let tabs: TabsModel
    let layout: Configuration.Layout
    @State private var suggestions = SuggestionSource()
    @FocusState private var typing: Bool

    var body: some View {
        if let bar = tabs.bar {
            let settings = PaneContentKinds.webSettings
            let shown = bar.purpose == .search ? suggestions.suggestions : []
            let rows = CommandBarRows.rows(bar, tabs: tabs, settings: settings, suggestions: shown)
            ZStack(alignment: .top) {
                Color.black.opacity(0.18)
                    .contentShape(.rect)
                    .onTapGesture { tabs.bar = nil }
                panel(bar, rows, settings)
                    .padding(.top, 56)
            }
            .transition(.opacity)
            .onAppear { typing = true }
            .onChange(of: bar.query + "\u{0}" + (bar.engine ?? ""), initial: true) {
                takeChip(settings)
                if let now = tabs.bar { ask(now, settings) }
            }
            .onChange(of: bar.showsActions) { _, open in if !open { typing = true } }
        }
    }

    private func panel(_ bar: CommandBar, _ rows: [ChoiceRow], _ settings: WebSettings) -> some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius + 8, style: .continuous)
        let selection = rows.isEmpty ? -1 : min(bar.selection, rows.count - 1)
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                if let engine = bar.engine { chip(engine) }
                field(bar, rows, selection, settings)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            if !rows.isEmpty {
                Divider().opacity(0.5)
                ChoiceList(rows: rows, selection: selection, radius: layout.tabRadius) { run(rows, $0, action: 0) }
            } else if !bar.query.isEmpty {
                Text("Nothing matches").foregroundStyle(.secondary).padding(14)
            }
        }
        .frame(width: 520)
        .glassEffect(.regular, in: shape)
        .overlay { shape.hairline(ShellSettings.Layout(layout)) }
        .overlay(alignment: .top) {
            if bar.showsActions, rows.indices.contains(selection) {
                CommandBarActionsPanel(tabs: tabs, row: rows[selection], radius: layout.tabRadius)
                    .padding(.top, 52)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 24, y: 8)
    }

    private func chip(_ engine: String) -> some View {
        Text(engine)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.accentColor.opacity(0.25)))
    }

    private func field(_ bar: CommandBar, _ rows: [ChoiceRow], _ selection: Int, _ settings: WebSettings) -> some View {
        TextField(bar.engine.map { "Search \($0)\u{2026}" } ?? bar.prompt, text: query)
            .textFieldStyle(.plain)
            .font(.system(size: 17))
            .focused($typing)
            .onKeyPress(.return, phases: .down) { press in
                run(
                    rows,
                    selection,
                    action: press.modifiers.contains(.command) ? 1 : (press.modifiers.contains(.option) ? 2 : 0)
                )
                return .handled
            }
            .onKeyPress(.downArrow) { move(1, rows.count) }
            .onKeyPress(.upArrow) { bar.query.isEmpty || bar.recalled > 0 ? recall() : move(-1, rows.count) }
            .onKeyPress(.delete) {
                guard bar.query.isEmpty, bar.engine != nil else { return .ignored }
                tabs.bar?.engine = nil
                return .handled
            }
            .onKeyPress(keys: ["k"]) { press in
                guard press.modifiers.contains(.command), rows.indices.contains(selection) else { return .ignored }
                tabs.bar?.showsActions = true
                tabs.bar?.actionsQuery = ""
                tabs.bar?.actionsSelection = 0
                return .handled
            }
            .onKeyPress(.escape) {
                tabs.bar = nil
                return .handled
            }
    }

    private var query: Binding<String> {
        Binding(
            get: { tabs.bar?.query ?? "" },
            set: {
                tabs.bar?.selection = 0
                tabs.bar?.recalled = 0
                tabs.bar?.query = $0
            }
        )
    }

    /// An engine's keyword followed by a space becomes the chip (after the field has taken what was typed: changing it while it is set is not shown).
    private func takeChip(_ settings: WebSettings) {
        guard let bar = tabs.bar, bar.engine == nil, bar.purpose == .search, bar.query.hasSuffix(" "),
            !bar.query.dropLast().contains(" "),
            let engine = settings.engines.first(where: { $0.keyword.lowercased() == bar.query.dropLast().lowercased() })
        else { return }
        tabs.bar?.engine = engine.name
        tabs.bar?.query = ""
    }

    private func run(_ rows: [ChoiceRow], _ index: Int, action: Int) {
        guard rows.indices.contains(index) else { return }
        let actions = rows[index].actions
        actions[actions.indices.contains(action) ? action : 0].perform()
    }

    private func move(_ steps: Int, _ count: Int) -> KeyPress.Result {
        guard count > 0, let bar = tabs.bar else { return .handled }
        tabs.bar?.selection = TabSearch.moved(min(bar.selection, count - 1), by: steps, count: count)
        return .handled
    }

    /// Up in the empty field (and again after): the entry before the one shown.
    private func recall() -> KeyPress.Result {
        guard let bar = tabs.bar, bar.recalled < tabs.barRecall.count else { return .handled }
        let entry = tabs.barRecall[tabs.barRecall.count - 1 - bar.recalled]
        tabs.bar?.query = entry
        tabs.bar?.recalled = bar.recalled + 1
        tabs.bar?.selection = 0
        return .handled
    }

    private func ask(_ bar: CommandBar, _ settings: WebSettings) {
        let chip = bar.engine.flatMap { name in settings.engines.first { $0.name == name } }
        let question =
            bar.purpose == .search ? SuggestionSource.question(bar.query, settings: settings, chip: chip) : nil
        suggestions.update(bar.query, engine: question?.0, words: question?.1 ?? "", enabled: settings.suggestions)
    }
}
