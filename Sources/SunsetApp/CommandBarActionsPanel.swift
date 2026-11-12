import SunsetPane
import SunsetShell
import SwiftUI

/// The actions of the command bar's selected row (Cmd-K): a field that filters them and their list, each with its key. Return does the selected one,
/// Escape goes back to the rows.
struct CommandBarActionsPanel: View {
    let tabs: TabsModel
    let row: ChoiceRow
    let radius: Double
    @FocusState private var typing: Bool

    private var actions: [ChoiceAction] {
        let query = tabs.bar?.actionsQuery.lowercased() ?? ""
        return query.isEmpty ? row.actions : row.actions.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        let actions = actions
        let selection = actions.isEmpty ? -1 : min(tabs.bar?.actionsSelection ?? 0, actions.count - 1)
        let rows = actions.map {
            ChoiceRow(id: $0.id, glyph: .symbol($0.symbol), title: $0.title, accessory: $0.key, actions: [$0])
        }
        VStack(spacing: 0) {
            TextField("Search for actions\u{2026}", text: query)
                .textFieldStyle(.plain)
                .padding(.horizontal, Design.Space.l)
                .frame(height: Design.Size.row)
                .focused($typing)
                .onKeyPress(.return) {
                    if actions.indices.contains(selection) { actions[selection].perform() }
                    return .handled
                }
                .onKeyPress(.downArrow) { move(1, actions.count) }
                .onKeyPress(.upArrow) { move(-1, actions.count) }
                .onKeyPress(.escape) { close() }
                .onKeyPress(keys: ["k"]) { press in press.modifiers.contains(.command) ? close() : .ignored }
            Divider().opacity(0.5)
            ChoiceList(rows: rows, selection: selection, radius: radius) { index in actions[index].perform() }
        }
        .frame(width: Design.Width.popover)
        .surface(
            RoundedRectangle(
                cornerRadius: Design.Radius.container(holding: radius, inset: Design.Space.s),
                style: .continuous
            ),
            shadow: .popover
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, Design.Space.l)
        .onAppear { typing = true }
    }

    private var query: Binding<String> {
        Binding(
            get: { tabs.bar?.actionsQuery ?? "" },
            set: {
                tabs.bar?.actionsQuery = $0
                tabs.bar?.actionsSelection = 0
            }
        )
    }

    private func move(_ steps: Int, _ count: Int) -> KeyPress.Result {
        guard count > 0 else { return .handled }
        // Read before writing: `tabs.bar?.x = f(tabs.bar)` reads the property while it is being changed (a crash, seen on 2026-11-12).
        let current = tabs.bar?.actionsSelection ?? 0
        tabs.bar?.actionsSelection = TabSearch.moved(
            min(current, count - 1),
            by: steps,
            count: count
        )
        return .handled
    }

    private func close() -> KeyPress.Result {
        tabs.bar?.showsActions = false
        return .handled
    }
}
