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
            .gesture(WindowDragGesture())
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
        let armed = tabs.isCloseArmed(item.id)
        return HStack(spacing: 6) {
            TabLabel(
                model: tabs.models[item.focused],
                showIcon: settings.showIcon,
                showTitle: settings.showTitle,
                showDirectory: settings.showDirectory,
                showProgress: settings.showProgress,
                name: tabs.custom(for: item).name,
                icon: tabs.custom(for: item).icon
            )
            .frame(maxWidth: 180, alignment: .leading)
            if hovered == item.id || selected || armed {
                Button {
                    tabs.close(item: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(armed ? Color.red : Color.primary)
                }
                .buttonStyle(.borderless)
                .help(armed ? "Click again to close running command" : "Close Tab")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            armed
                ? AnyShapeStyle(Color.red.opacity(0.24))
                : (selected ? AnyShapeStyle(.selection.opacity(0.35)) : AnyShapeStyle(Color.clear)),
            in: .rect(cornerRadius: 6)
        )
        .contentShape(.rect)
        .onTapGesture { tabs.select(item: item.id) }
        .onHover { inside in
            hovered = inside ? item.id : (hovered == item.id ? nil : hovered)
            if inside {
                tabs.hoveredItem = item.id
            } else if tabs.hoveredItem == item.id {
                tabs.hoveredItem = nil
            }
        }
        .onDrag { tabs.itemProvider(for: .item(item.id)) }
        .dropDestination(for: String.self) { items, _ in
            guard let text = items.first, case .item(let id)? = PaneDragPayload(text: text),
                let index = tabs.workspace.items.firstIndex(where: { $0.id == item.id })
            else { return false }
            tabs.move(item: id, to: index)
            return true
        }
        .contextMenu {
            Button("Rename Tab…") { tabs.beginRename(item: item.id) }
            Button("Close Tab") { tabs.close(item: item.id) }
            Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                .disabled(tabs.workspace.count < 2)
        }
    }
}
