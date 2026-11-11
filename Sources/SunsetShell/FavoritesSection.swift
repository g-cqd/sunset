import SunsetPane
import SwiftUI

/// The Favorites at the top of the sidebar (R3, R4): kept entries and folders, then a thin line above the window's own tabs. A click opens an entry and
/// shows it; while it is open its row has a minus that unloads it; one that is not open is drawn fainter and has an x that removes it.
struct FavoritesSection: View {
    let tabs: TabsModel
    let settings: ShellSettings
    let layout: ShellSettings.Layout

    var body: some View {
        let favorites = tabs.favorites.favorites
        if !favorites.isEmpty {
            ForEach(favorites.rows(selected: tabs.workspace.selectedEntry)) { row in
                Group {
                    switch favorites.node(row.id) {
                        case .entry(let entry): entryRow(entry)
                        case .folder(let folder): folderRow(folder)
                        case nil: EmptyView()
                    }
                }
                .padding(.leading, Double(row.level) * 12)
            }
            Rectangle()
                .fill(.primary.opacity(layout.hairlineOpacity * 1.5))
                .frame(height: max(layout.hairlineWidth, 0.5))
                .padding(.horizontal, layout.tabPaddingLeading)
                .padding(.vertical, 2)
        }
    }

    private func entryRow(_ entry: Favorites.Entry) -> some View {
        SidebarRow(
            model: entry.open.flatMap { tabs.favorites.contents[$0.focused] },
            selected: tabs.workspace.selectedEntry == entry.id,
            armed: entry.open.map { tabs.isCloseArmed($0.id) } ?? false,
            name: entry.title,
            icon: entry.icon,
            saved: entry.home.contents[entry.home.focused],
            showIcon: settings.tabs.bar.showIcon,
            showTitle: settings.tabs.bar.showTitle,
            showDirectory: settings.tabs.bar.showDirectory,
            showProgress: settings.tabs.bar.showProgress,
            layout: layout,
            button: entry.isOpen ? .unload : .delete,
            dimmed: !entry.isOpen,
            close: { entry.isOpen ? tabs.unload(entry: entry.id) : tabs.delete(entry: entry.id) }
        )
        .onTapGesture { tabs.select(entry: entry.id) }
        .contextMenu {
            Button("Remove from Favorites") { tabs.release(entry: entry.id) }
            if entry.isOpen {
                Button("Set Home to Current") { tabs.favorites.setHomeToCurrent(entry.id) }
                Button("Unload") { tabs.unload(entry: entry.id) }
            }
            Button("Delete") { tabs.delete(entry: entry.id) }
        }
    }

    private func folderRow(_ folder: Favorites.Folder) -> some View {
        Label(folder.name, systemImage: folder.isCollapsed ? "folder" : "folder.fill")
            .font(.system(size: 12))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.vertical, layout.tabPaddingVertical + 2)
            .contentShape(.rect)
            .onTapGesture { tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) } }
    }
}
