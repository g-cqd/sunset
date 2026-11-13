import SunsetMetrics
import SunsetPane
import SwiftUI

extension BuiltInTabBar {
    @ViewBuilder func barItem(_ item: Favorites.BarItem) -> some View {
        switch item {
            case .entry(let id):
                if let entry = tabs.favorites.favorites.entry(id) { entryRow(entry) }
            case .folder(let id, let count):
                if case .folder(let folder)? = tabs.favorites.favorites.node(id) { folderRow(folder, count: count) }
        }
    }

    /// A folder of the Favorites (R3 step f): its icon and name, its count of open entries while collapsed; a click opens or closes it.
    private func folderRow(_ folder: Favorites.Folder, count: Int) -> some View {
        BarTab(selected: false, close: nil) {
            if let icon = folder.icon, PaneIconView.canShow(icon) {
                PaneIconView(icon: icon)
            } else {
                Image(systemName: folder.isCollapsed ? "folder" : "folder.fill").foregroundStyle(.secondary)
            }
        } label: {
            HStack(spacing: Design.Space.xs) {
                Text(folder.name).lineLimit(1)
                if folder.isCollapsed {
                    Text("\(count)").font(Design.Text.tiny.monospacedDigit()).foregroundStyle(.secondary)
                        .padding(.horizontal, Design.Space.xs)
                        .background(.primary.opacity(Design.Fill.openHover), in: Capsule())
                }
            }
        }
        .onTapGesture { tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) } }
        .help(
            folder.isCollapsed
                ? "Show what \u{201C}\(folder.name)\u{201D} holds" : "Hide what \u{201C}\(folder.name)\u{201D} holds"
        )
    }

    private func entryRow(_ entry: Favorites.Entry) -> some View {
        let model = entry.open.flatMap { tabs.favorites.contents[$0.focused] }
        return BarTab(
            selected: tabs.workspace.selectedEntry == entry.id,
            armed: entry.open.map { tabs.isCloseArmed($0.id) } ?? false,
            button: .unload,
            close: { tabs.unload(entry: entry.id) },
            icon: { TabIcon(model: model, icon: entry.icon, saved: entry.home.contents[entry.home.focused]) },
            label: { label(model: model, name: entry.title) },
            lines: lines
        )
        .help(capsules ? entry.title ?? "" : "")
        .onTapGesture { tabs.select(entry: entry.id) }
        .contextMenu {
            Button("Remove from Favorites") { tabs.release(entry: entry.id) }
            Button("Edit Command…") { tabs.editingCommand = entry.id }
            Button("Set Home to Current") { tabs.favorites.setHomeToCurrent(entry.id) }
            Button("Unload") { tabs.unload(entry: entry.id) }
            Button("Delete") { tabs.delete(entry: entry.id) }
        }
    }

    func row(_ item: Workspace.Item) -> some View {
        let model = tabs.contents[item.focused]
        let custom = tabs.custom(for: item)
        return BarTab(
            selected: tabs.isSelected(item.id),
            armed: tabs.isCloseArmed(item.id),
            close: { tabs.close(item: item.id) },
            icon: { TabIcon(model: model, icon: custom.icon) },
            label: { label(model: model, name: custom.name) },
            lines: lines,
            onHover: { inside in hover(item.id, inside) }
        )
        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frames[item.id] = $0 }
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
            Button("Rename Tab…") { tabs.beginRename(item: item.id) }
            Button("Add to Favorites") { tabs.keep(item: item.id) }
            Button("Close Tab") { tabs.close(item: item.id) }
            Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }.disabled(tabs.workspace.count < 2)
        }
    }

    private var lines: Int { settings.showDirectory ? 2 : 1 }

    /// The title and the second line, without the icon (the bar's tab draws it in the slot it shares with the close button).
    private func label(model: (any PaneContent)?, name: String?) -> some View {
        TabLabel(
            model: model,
            showIcon: false,
            showTitle: settings.showTitle,
            showDirectory: settings.showDirectory,
            showProgress: settings.showProgress,
            name: name
        )
    }

    /// The pointer over a tab: its preview follows (the sidebar's hover preview).
    private func hover(_ id: UUID, _ inside: Bool) {
        if inside {
            tabs.hoveredItem = id
            tabs.hoveredRowFrame = frames[id]
        } else if tabs.hoveredItem == id {
            tabs.hoveredItem = nil
        }
    }
}
