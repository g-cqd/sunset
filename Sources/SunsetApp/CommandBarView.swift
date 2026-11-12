import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// The command bar: a field and a list of the open tabs under it, over the window's content (⌘L from anywhere in the app). Typing filters the tabs
/// (`TabSearch`), the arrows move the selection, Return does what the bar was opened for with the selected tab, Escape or a click outside closes it.
struct CommandBarView: View {
    let tabs: TabsModel
    let layout: Configuration.Layout
    @FocusState private var typing: Bool

    var body: some View {
        if let bar = tabs.bar {
            let results = tabs.barResults(bar)
            let address = bar.purpose == .search ? WebAddress.typedAddress(bar.query) : nil
            ZStack(alignment: .top) {
                Color.black.opacity(0.18)
                    .contentShape(.rect)
                    .onTapGesture { tabs.bar = nil }
                panel(bar, results, address)
                    .padding(.top, 56)
            }
            .transition(.opacity)
            .onAppear { typing = true }
        }
    }

    private func panel(_ bar: CommandBar, _ results: [Workspace.Item], _ address: URL?) -> some View {
        let count = results.count + (address == nil ? 0 : 1)
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius + 8, style: .continuous)
        return VStack(spacing: 0) {
            TextField(bar.prompt, text: query)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .frame(height: 46)
                .focused($typing)
                .onSubmit { submit(bar, results, address) }
                .onKeyPress(.downArrow) { move(1, count) }
                .onKeyPress(.upArrow) { move(-1, count) }
                .onKeyPress(.escape) {
                    tabs.bar = nil
                    return .handled
                }
            if count > 0 {
                Divider().opacity(0.5)
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                            row(item, selected: index == min(bar.selection, results.count - 1)) {
                                tabs.accept(item.id, in: bar)
                            }
                        }
                        if let address { goRow(address, selected: min(bar.selection, count - 1) == results.count) }
                    }
                    .padding(6)
                }
                // As tall as its rows (a scroll view would take all the room it is offered), up to a limit.
                .frame(height: min(Double(count) * 34 + 12, 280))
            } else if !bar.query.isEmpty {
                Text("No tab matches").foregroundStyle(.secondary).padding(14)
            }
        }
        .frame(width: 520)
        .glassEffect(.regular, in: shape)
        .overlay { shape.hairline(ShellSettings.Layout(layout)) }
        .shadow(color: .black.opacity(0.3), radius: 24, y: 8)
    }

    private var query: Binding<String> {
        Binding(
            get: { tabs.bar?.query ?? "" },
            set: {
                tabs.bar?.query = $0
                tabs.bar?.selection = 0
            }
        )
    }

    /// Return: the selected tab, or the address row (the last row).
    private func submit(_ bar: CommandBar, _ results: [Workspace.Item], _ address: URL?) {
        let count = results.count + (address == nil ? 0 : 1)
        guard count > 0 else { return }
        let index = min(bar.selection, count - 1)
        if index < results.count {
            tabs.accept(results[index].id, in: bar)
        } else if let address {
            tabs.bar = nil
            AppActions.shared.go(to: address, in: tabs)
        }
    }

    /// Go to what was typed: in the focused page, or a new page when a terminal has the keyboard.
    private func goRow(_ address: URL, selected: Bool) -> some View {
        Button {
            tabs.bar = nil
            AppActions.shared.go(to: address, in: tabs)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe").frame(width: 16)
                Text("Go to \(address.absoluteString)").lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                    .fill(Color.primary.opacity(selected ? 0.14 : 0))
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func move(_ steps: Int, _ count: Int) -> KeyPress.Result {
        guard count > 0, let bar = tabs.bar else { return .handled }
        tabs.bar?.selection = TabSearch.moved(min(bar.selection, count - 1), by: steps, count: count)
        return .handled
    }

    private func row(_ item: Workspace.Item, selected: Bool, action: @escaping () -> Void) -> some View {
        let model = tabs.contents[item.focused]
        return Button(action: action) {
            HStack(spacing: 8) {
                if let model { PaneGlyphView(glyph: model.glyph) }
                Text(model?.title ?? "Sunset").lineLimit(1)
                if let directory = model?.detail {
                    Text(TabLabel.shortened(directory)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
                if item.isSplit { Text("\(item.panes.count) panes").font(.caption).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                    .fill(Color.primary.opacity(selected ? 0.14 : 0))
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
