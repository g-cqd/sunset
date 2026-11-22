import SunsetConfig
import SunsetMetrics
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// The command bar: a field and the rows under it, over the window's content (Cmd-L from anywhere in the app): the tabs that match (`TabSearch`), what
/// was typed as an address or a search, the engine's suggestions (`CommandBarRows`). The arrows move the keyboard's row, Return does its first action,
/// Cmd-Return its second, Option-Return its third, Cmd-K lists them all (`CommandBarActionsPanel`); Up in the empty field recalls earlier entries; an
/// engine's keyword and a space become a chip; Escape or a click outside closes it.
struct CommandBarView: View {
    @Environment(\.runtime) var runtime

    let tabs: TabsModel
    let layout: Configuration.Layout
    /// The sidebar's field it opens in: its field is that size, its rows as wide; nil over the panes.
    var anchor: CGSize?
    /// The room it is shown in (the panes' width, the window's height): it fits in it.
    var room: CGSize?
    @State private var suggestions = SuggestionSource()
    @FocusState private var typing: Bool

    @Environment(\.accent) private var accent
    @Environment(\.barTint) private var tint
    @Environment(\.colorScheme) private var outer

    var body: some View {
        if let bar = tabs.bar {
            let settings = PaneContentKinds.webSettings(for: tabs)
            let shown = bar.purpose == .search ? suggestions.suggestions : []
            let rows = CommandBarRows.rows(bar, tabs: tabs, settings: settings, suggestions: shown)
            // Its backdrop is the window's (`WindowDialogs`), under the address bar.
            panel(bar, rows, settings)
                .padding(.top, anchor == nil ? Design.System.commandBarTop : 0)
                .transition(.opacity)
                // The field takes the keyboard as the bar shows; asked again once it is in the window, where the terminal
                // kept it before (typed text went to the terminal, 2026-11-17).
                .onAppear { typing = true }
                .task {
                    for wait in [16, 50, 120] {
                        await runtime.sleep(for: .milliseconds(wait))
                        if !typing { typing = true }
                    }
                }
                .onChange(of: bar.query + "\u{0}" + (bar.engine ?? ""), initial: true) {
                    takeChip(settings)
                    if let now = tabs.bar { ask(now, settings) }
                }
                .onChange(of: bar.showsActions) { _, open in if !open { typing = true } }
        }
    }

    /// The height left for the rows under the field, in the room it has.
    private var listRoom: Double {
        guard let room else { return .infinity }
        let top = anchor == nil ? Design.System.commandBarTop : 0
        return max(
            0,
            CommandBarSize.height(room: room.height, top: top)
                - (anchor.map { Double($0.height) } ?? Design.Size.fieldLarge)
        )
    }

    private func panel(_ bar: CommandBar, _ rows: [ChoiceRow], _ settings: WebSettings) -> some View {
        let style = SurfaceStyle(layout: layout)
        let selection = rows.isEmpty ? -1 : min(bar.selection, rows.count - 1)
        let scheme = tint.resolved(in: outer)
        return VStack(spacing: 0) {
            HStack(spacing: Design.Space.s) {
                if let engine = bar.engine { chip(engine) }
                field(bar, rows, selection, settings)
            }
            .padding(.horizontal, anchor == nil ? Design.Space.xl : layout.tabPaddingLeading)
            .frame(height: anchor.map { Double($0.height) } ?? Design.Size.fieldLarge)
            if !rows.isEmpty {
                Divider().opacity(Design.Fill.fainterDivider)
                // Under the sidebar's field, rows as its tabs: their space between them, 2 pt closer to the edge; the
                // large bar's rows a little further apart than they were.
                ChoiceList(
                    rows: rows,
                    selection: selection,
                    radius: layout.tabRadius,
                    spacing: anchor == nil ? Design.Space.xs : layout.tabSpacing,
                    inset: anchor == nil ? Design.Space.s : Design.Space.xs,
                    maxHeight: listRoom
                ) { run(rows, $0, action: 0) }
            } else if !bar.query.isEmpty {
                Text("Nothing matches").foregroundStyle(.secondary).padding(Design.Space.xl)
            }
        }
        .frame(
            width: anchor.map { Double($0.width) } ?? room.map { CommandBarSize.width(room: $0.width) }
                ?? Design.Width.commandBar
        )
        // The bars' tint (`appearance.barTint`), its scheme set inside the glass, as the address bar's groups; the backdrop under it blurs the rest.
        .environment(\.colorScheme, scheme)
        .background { style.shape.fill(BarTint.fill(for: scheme).opacity(Design.Fill.barShade)) }
        .glassEffect(.regular, in: style.shape)
        .overlay(alignment: .top) {
            if bar.showsActions, rows.indices.contains(selection) {
                CommandBarActionsPanel(tabs: tabs, row: rows[selection], radius: style.leafRadius)
                    .padding(.top, (anchor.map { Double($0.height) } ?? Design.Size.fieldLarge) + Design.Space.s)
            }
        }
    }

    private func chip(_ engine: String) -> some View {
        Text(engine)
            .font(Design.Text.body.weight(.medium))
            .padding(.horizontal, Design.Space.m)
            .padding(.vertical, Design.Space.hair)
            .background(Capsule().fill(accent.color.opacity(Design.Fill.target)))
    }

    private func field(_ bar: CommandBar, _ rows: [ChoiceRow], _ selection: Int, _ settings: WebSettings) -> some View {
        let prompt = anchor != nil && bar.purpose == .search ? SidebarCommandField.prompt : bar.prompt
        return TextField(bar.engine.map { "Search \($0)\u{2026}" } ?? prompt, text: query)
            .textFieldStyle(.plain)
            .font(anchor == nil ? Design.Text.input : Design.Text.body)
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

    /// An engine's keyword followed by a space starts what is typed: it becomes the chip, the rest stays typed (typing fast may skip the moment
    /// the text is just the keyword and the space).
    private func takeChip(_ settings: WebSettings) {
        guard let bar = tabs.bar, bar.engine == nil, bar.purpose == .search, let space = bar.query.firstIndex(of: " "),
            let engine = settings.engines.first(where: { $0.keyword.lowercased() == bar.query[..<space].lowercased() })
        else { return }
        tabs.bar?.engine = engine.name
        tabs.bar?.query = String(bar.query[bar.query.index(after: space)...])
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
        suggestions.update(
            bar.query,
            engine: question?.0,
            words: question?.1 ?? "",
            enabled: settings.suggestsWhileTyping,
            userAgent: settings.userAgent
        )
    }
}
