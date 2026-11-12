import SunsetPane
package import SwiftUI

/// The tab bar of our own, for `tabs.mode: internal`: one window, many terminals. Position and what a tab shows come from the configuration. The kept
/// entries that are open come first, each with a small star, then a thin line and the window's tabs (R3). Tabs are selected by a click, closed by their
/// button or the menu, and reordered by dragging; an entry's button unloads it (it stays in the Favorites).
package struct BuiltInTabBar: View {
    let tabs: TabsModel
    let settings: ShellSettings.Bar
    @State private var hovered: UUID?
    @Environment(\.accent) private var accent
    @Environment(\.surfaceStyle) private var surface
    @State private var frames: [UUID: CGRect] = [:]

    package init(tabs: TabsModel, settings: ShellSettings.Bar) {
        self.tabs = tabs
        self.settings = settings
    }

    package var body: some View {
        HStack(spacing: Design.Space.hair) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Space.hair) {
                    let items = tabs.favorites.favorites.barItems(selected: tabs.workspace.selectedEntry)
                    ForEach(items, id: \.self) { item in barItem(item) }
                    if !items.isEmpty {
                        Rectangle().fill(.primary.opacity(Design.Fill.separator)).frame(width: 1, height: 16)
                            .padding(.horizontal, Design.Space.xs)
                    }
                    ForEach(tabs.workspace.items) { item in row(item) }
                }
                .padding(.horizontal, Design.Space.xs)
            }
            .gesture(WindowDragGesture())
            SwiftUI.Button {
                tabs.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, Design.Space.s)
        }
        .frame(height: settings.showDirectory || settings.showProgress ? 40 : 30)
        .background(.bar)
    }

    @ViewBuilder private func barItem(_ item: Favorites.BarItem) -> some View {
        switch item {
            case .entry(let id):
                if let entry = tabs.favorites.favorites.entry(id) { entryRow(entry) }
            case .folder(let id, let count):
                if case .folder(let folder)? = tabs.favorites.favorites.node(id) { folderChip(folder, count: count) }
        }
    }

    /// A folder of the Favorites (R3 step f): its icon and name, its count of open entries while collapsed; a click opens or closes it, as in the sidebar.
    private func folderChip(_ folder: Favorites.Folder, count: Int) -> some View {
        HStack(spacing: Design.Space.xs) {
            if let icon = folder.icon, PaneIconView.canShow(icon) {
                PaneIconView(icon: icon)
            } else {
                Image(systemName: folder.isCollapsed ? "folder" : "folder.fill").foregroundStyle(.secondary)
            }
            Text(folder.name).lineLimit(1)
            if folder.isCollapsed {
                Text("\(count)").font(Design.Text.tiny.monospacedDigit()).foregroundStyle(.secondary)
                    .padding(.horizontal, Design.Space.xs)
                    .background(.primary.opacity(Design.Fill.openHover), in: Capsule())
            }
        }
        .font(Design.Text.secondary)
        .padding(.horizontal, Design.Space.m)
        .padding(.vertical, Design.Space.xs)
        .contentShape(.rect)
        .onTapGesture { tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) } }
        .help(
            folder.isCollapsed
                ? "Show what \u{201C}\(folder.name)\u{201D} holds" : "Hide what \u{201C}\(folder.name)\u{201D} holds"
        )
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
            HStack(spacing: Design.Space.xs) {
                Image(systemName: "star.fill").font(.system(size: Design.Symbol.mark)).foregroundStyle(.secondary)
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
            SwiftUI.Button("Edit Command…") { tabs.editingCommand = entry.id }
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
        HStack(spacing: Design.Space.s) {
            content()
            if hovered == id || selected || armed {
                SwiftUI.Button(action: button.action) {
                    Image(systemName: button.symbol)
                        .font(Design.Text.tiny)
                        .foregroundStyle(armed ? Color.red : Color.primary)
                }
                .buttonStyle(.borderless)
                .help(armed ? "Click again to close running command" : button.help)
            }
        }
        .padding(.horizontal, Design.Space.l)
        .padding(.vertical, Design.Space.xs)
        .background(
            armed
                ? AnyShapeStyle(Color.red.opacity(Design.Fill.armed))
                : (selected
                    ? AnyShapeStyle(accent.color.opacity(Design.Fill.markedHover)) : AnyShapeStyle(Color.clear)),
            in: .rect(cornerRadius: surface.leafRadius)
        )
        .contentShape(.rect)
        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frames[id] = $0 }
        .onHover { inside in
            hovered = inside ? id : (hovered == id ? nil : hovered)
            if inside {
                tabs.hoveredItem = id
                tabs.hoveredRowFrame = frames[id]
            } else if tabs.hoveredItem == id {
                tabs.hoveredItem = nil
            }
        }
    }
}
