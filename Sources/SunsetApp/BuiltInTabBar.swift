import SunsetConfig
import SunsetHost
import SwiftUI

/// The tab bar of our own, for `tabs.mode: internal`: one window, many terminals. Position and what a tab shows come from the configuration. Tabs are
/// selected by a click, closed by their button or the menu, and reordered by dragging.
struct BuiltInTabBar: View {
    let tabs: TabsModel
    let settings: Configuration.Tabs.Bar
    @State private var hovered: TabList.ID?

    var body: some View {
        HStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs.list.tabs) { tab in row(tab) }
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

    private func row(_ tab: TabList.Tab) -> some View {
        let selected = tab.id == tabs.list.selectedID
        return HStack(spacing: 6) {
            TabLabel(
                model: tabs.models[tab.id],
                showTitle: settings.showTitle,
                showDirectory: settings.showDirectory,
                showProgress: settings.showProgress
            )
            .frame(maxWidth: 180, alignment: .leading)
            if hovered == tab.id || selected {
                Button {
                    tabs.close(tab.id)
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
        .onTapGesture { tabs.select(tab.id) }
        .onHover { inside in hovered = inside ? tab.id : (hovered == tab.id ? nil : hovered) }
        .draggable(tab.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let text = items.first, let id = UUID(uuidString: text),
                let index = tabs.list.tabs.firstIndex(where: { $0.id == tab.id })
            else { return false }
            tabs.move(id, to: index)
            return true
        }
        .contextMenu {
            Button("Close Tab") { tabs.close(tab.id) }
            Button("Close Other Tabs") {
                for other in tabs.list.tabs where other.id != tab.id { tabs.close(other.id) }
            }
            .disabled(tabs.list.count < 2)
        }
    }
}
