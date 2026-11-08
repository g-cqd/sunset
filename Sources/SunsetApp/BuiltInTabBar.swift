import SunsetConfig
import SunsetPane
import SwiftUI

/// The tab bar of our own, for `tabs.mode: internal`: one window, many terminals. Position and what a tab shows come from the configuration. Tabs are
/// selected by a click, closed by their button or the menu, and reordered by dragging.
struct BuiltInTabBar: View {
    let tabs: TabsModel
    let settings: Configuration.Tabs.Bar
    @State private var hovered: Workspace.ItemID?

    var body: some View {
        HStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs.workspace.items) { item in row(item) }
                }
                .padding(.horizontal, 4)
            }
            Button {
                tabs.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, 6)
        }
        .frame(height: settings.showDirectory || settings.showProgress ? 40 : 30)
        .background(.bar)
    }

    private func row(_ item: Workspace.Item) -> some View {
        let selected = item.id == tabs.workspace.selectedID
        return HStack(spacing: 6) {
            TabLabel(
                model: tabs.models[item.focused],
                showTitle: settings.showTitle,
                showDirectory: settings.showDirectory,
                showProgress: settings.showProgress
            )
            .frame(maxWidth: 180, alignment: .leading)
            if hovered == item.id || selected {
                Button {
                    tabs.close(item: item.id)
                } label: {
                    Image(systemName: "xmark").font(.caption2)
                }
                .buttonStyle(.borderless)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            selected ? AnyShapeStyle(.selection.opacity(0.35)) : AnyShapeStyle(.clear),
            in: .rect(cornerRadius: 6)
        )
        .contentShape(.rect)
        .onTapGesture { tabs.select(item: item.id) }
        .onHover { inside in hovered = inside ? item.id : (hovered == item.id ? nil : hovered) }
        .draggable(item.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let text = items.first, let id = UUID(uuidString: text),
                let index = tabs.workspace.items.firstIndex(where: { $0.id == item.id })
            else { return false }
            tabs.move(item: id, to: index)
            return true
        }
        .contextMenu {
            Button("Close Tab") { tabs.close(item: item.id) }
            Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                .disabled(tabs.workspace.count < 2)
        }
    }
}
