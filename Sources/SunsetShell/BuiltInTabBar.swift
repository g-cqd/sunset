import SunsetPane
package import SwiftUI

/// The tab bar of our own, for `tabs.mode: internal`: one window, many terminals. Position and what a tab shows come from the configuration. The kept
/// entries that are open come first, each with a small star, then a thin line and the window's tabs (R3). Tabs are selected by a click, closed by their
/// button or the menu, and reordered by dragging; an entry's button unloads it (it stays in the Favorites).
package struct BuiltInTabBar: View {
    let tabs: TabsModel
    let settings: ShellSettings.Bar
    @State private var hovered: UUID?

    package init(tabs: TabsModel, settings: ShellSettings.Bar) {
        self.tabs = tabs
        self.settings = settings
    }

    package var body: some View {
        HStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    let open = tabs.favorites.favorites.entries.filter(\.isOpen)
                    ForEach(open) { entry in entryRow(entry) }
                    if !open.isEmpty {
                        Rectangle().fill(.primary.opacity(0.18)).frame(width: 1, height: 16).padding(.horizontal, 3)
                    }
                    ForEach(tabs.workspace.items) { item in row(item) }
                }
                .padding(.horizontal, 4)
            }
            .gesture(WindowDragGesture())
            SwiftUI.Button {
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

    private func entryRow(_ entry: Favorites.Entry) -> some View {
        let selected = tabs.workspace.selectedEntry == entry.id
        let armed = entry.open.map { tabs.isCloseArmed($0.id) } ?? false
        return chip(
            id: entry.id,
            selected: selected,
            armed: armed,
            button: (symbol: "minus", help: "Unload (it stays in Favorites)", action: { tabs.unload(entry: entry.id) })
        ) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.system(size: 7)).foregroundStyle(.secondary)
                label(
                    model: entry.open.flatMap { tabs.favorites.contents[$0.focused] },
                    name: entry.title,
                    icon: entry.icon
                )
            }
        }
        .onTapGesture { tabs.select(entry: entry.id) }
        .contextMenu {
            SwiftUI.Button("Remove from Favorites") { tabs.release(entry: entry.id) }
            SwiftUI.Button("Set Home to Current") { tabs.favorites.setHomeToCurrent(entry.id) }
            SwiftUI.Button("Unload") { tabs.unload(entry: entry.id) }
            SwiftUI.Button("Delete") { tabs.delete(entry: entry.id) }
        }
    }

    private func row(_ item: Workspace.Item) -> some View {
        chip(
            id: item.id,
            selected: tabs.isSelected(item.id),
            armed: tabs.isCloseArmed(item.id),
            button: (symbol: "xmark", help: "Close Tab", action: { tabs.close(item: item.id) })
        ) {
            label(
                model: tabs.contents[item.focused],
                name: tabs.custom(for: item).name,
                icon: tabs.custom(for: item).icon
            )
        }
        .onTapGesture { tabs.select(item: item.id) }
        .onDrag { tabs.itemProvider(for: .item(item.id)) }
        .dropDestination(for: String.self) { items, _ in
            guard let text = items.first, case .item(let id)? = PaneDragPayload(text: text),
                let index = tabs.workspace.items.firstIndex(where: { $0.id == item.id })
            else { return false }
            tabs.move(item: id, to: index)
            return true
        }
        .contextMenu {
            SwiftUI.Button("Rename Tab…") { tabs.beginRename(item: item.id) }
            SwiftUI.Button("Add to Favorites") { tabs.keep(item: item.id) }
            SwiftUI.Button("Close Tab") { tabs.close(item: item.id) }
            SwiftUI.Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                .disabled(tabs.workspace.count < 2)
        }
    }

    private func label(model: (any PaneContent)?, name: String?, icon: PaneIcon?) -> some View {
        TabLabel(
            model: model,
            showIcon: settings.showIcon,
            showTitle: settings.showTitle,
            showDirectory: settings.showDirectory,
            showProgress: settings.showProgress,
            name: name,
            icon: icon
        )
        .frame(maxWidth: 180, alignment: .leading)
    }

    /// One tab of the bar: its label, the button while it is hovered, selected or armed, and the highlight.
    private func chip(
        id: UUID,
        selected: Bool,
        armed: Bool,
        button: (symbol: String, help: String, action: () -> Void),
        @ViewBuilder content: () -> some View
    ) -> some View {
        HStack(spacing: 6) {
            content()
            if hovered == id || selected || armed {
                SwiftUI.Button(action: button.action) {
                    Image(systemName: button.symbol)
                        .font(.caption2)
                        .foregroundStyle(armed ? Color.red : Color.primary)
                }
                .buttonStyle(.borderless)
                .help(armed ? "Click again to close running command" : button.help)
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
        .onHover { inside in
            hovered = inside ? id : (hovered == id ? nil : hovered)
            if inside {
                tabs.hoveredItem = id
            } else if tabs.hoveredItem == id {
                tabs.hoveredItem = nil
            }
        }
    }
}
