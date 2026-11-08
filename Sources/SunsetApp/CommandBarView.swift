import SunsetConfig
import SunsetPane
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
            ZStack(alignment: .top) {
                Color.black.opacity(0.18)
                    .contentShape(.rect)
                    .onTapGesture { tabs.bar = nil }
                panel(bar, results)
                    .padding(.top, 56)
            }
            .transition(.opacity)
            .onAppear { typing = true }
        }
    }

    private func panel(_ bar: CommandBar, _ results: [Workspace.Item]) -> some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius + 8, style: .continuous)
        return VStack(spacing: 0) {
            TextField(bar.prompt, text: query)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .frame(height: 46)
                .focused($typing)
                .onSubmit { if let row = chosen(bar, results) { tabs.accept(row.id, in: bar) } }
                .onKeyPress(.downArrow) { move(1, results.count) }
                .onKeyPress(.upArrow) { move(-1, results.count) }
                .onKeyPress(.escape) {
                    tabs.bar = nil
                    return .handled
                }
            if !results.isEmpty {
                Divider().opacity(0.5)
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                            row(item, selected: index == min(bar.selection, results.count - 1)) {
                                tabs.accept(item.id, in: bar)
                            }
                        }
                    }
                    .padding(6)
                }
                // As tall as its rows (a scroll view would take all the room it is offered), up to a limit.
                .frame(height: min(Double(results.count) * 34 + 12, 280))
            } else if !bar.query.isEmpty {
                Text("No tab matches").foregroundStyle(.secondary).padding(14)
            }
        }
        .frame(width: 520)
        .glassEffect(.regular, in: shape)
        .overlay { shape.hairline(layout) }
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

    private func chosen(_ bar: CommandBar, _ results: [Workspace.Item]) -> Workspace.Item? {
        results.isEmpty ? nil : results[min(bar.selection, results.count - 1)]
    }

    private func move(_ steps: Int, _ count: Int) -> KeyPress.Result {
        guard count > 0, let bar = tabs.bar else { return .handled }
        tabs.bar?.selection = TabSearch.moved(min(bar.selection, count - 1), by: steps, count: count)
        return .handled
    }

    private func row(_ item: Workspace.Item, selected: Bool, action: @escaping () -> Void) -> some View {
        let model = tabs.models[item.focused]
        return Button(action: action) {
            HStack(spacing: 8) {
                if let model { TabGlyphView(glyph: TabLabel.glyph(of: model)) }
                Text(model?.title ?? "Sunset").lineLimit(1)
                if let directory = model?.directory {
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
