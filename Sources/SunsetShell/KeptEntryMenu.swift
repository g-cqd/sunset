import SunsetPane
import SwiftUI

/// The menu of a kept entry, the same wherever the entry is shown (a row of the Favorites, a tile of the Pinned grid, a
/// tab of the built-in bar): where it is kept (pinned, a favourite, a tab again), its name and icon, its command, what
/// it starts from, and unloading or deleting it. The owner, 2026-11-17: the menus did not hold everything about pinning
/// and favourites, and a favourite could not be pinned.
struct KeptEntryMenu: View {
    let tabs: TabsModel
    let entry: Favorites.Entry
    /// Whether the row can be renamed and given an icon where it is (the built-in bar's tabs cannot).
    var editsInPlace = true
    var animation: Animation?

    private var isPinned: Bool { tabs.isPinned(entry.id) }
    private var keeper: FavoritesModel { tabs.keeper(of: entry.id) }

    var body: some View {
        Button(entry.isOpen ? "Show" : "Open") { tabs.select(entry: entry.id) }
        Divider()
        if isPinned {
            Button("Unpin") { withAnimation(animation) { _ = tabs.release(entry: entry.id) } }
            Button("Move to Favorites") { withAnimation(animation) { _ = tabs.favorite(pinned: entry.id) } }
        } else {
            Button("Pin") { withAnimation(animation) { _ = tabs.pin(entry: entry.id) } }
                .disabled(!tabs.canPin(.node(entry.id)))
            Button("Remove from Favorites") { withAnimation(animation) { _ = tabs.release(entry: entry.id) } }
        }
        Divider()
        if editsInPlace {
            Button("Rename") { tabs.renamingRow = .node(entry.id) }
            Button("Change Icon\u{2026}") { tabs.iconRow = .node(entry.id) }
        }
        Button("Edit Command\u{2026}") { tabs.editingCommand = entry.id }
        if entry.isOpen, entry.command != nil {
            Button("Run Command Now") { keeper.runCommandNow(entry.id) }.disabled(!keeper.isTrusted(entry.id))
        }
        Divider()
        // Where it starts from: gone back to, or set to where it is now.
        Button(isPinned ? "Reset to Where It Was Pinned" : "Reset to Home") { tabs.reset(entry: entry.id) }
        if entry.isOpen {
            Button(isPinned ? "Pin Where It Is Now" : "Set Home to Current") { keeper.setHomeToCurrent(entry.id) }
            Button("Unload") { tabs.unload(entry: entry.id) }
            // While it is open: unloading it lets go (roadmap 0036 C).
            KeepAwakeMenu(tabs: tabs, entry: entry.id)
        }
        Divider()
        Button("Delete", role: .destructive) { tabs.delete(entry: entry.id) }
    }
}
