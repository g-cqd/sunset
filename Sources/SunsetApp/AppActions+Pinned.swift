import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The Pinned grid from the menu bar (P-b).
extension AppActions {
    /// Pins the tab or the favourite the acting window shows, or unpins the pinned entry it shows (it is a tab again).
    func togglePinned() {
        // A pinned entry is a tab again; a favourite is pinned; a tab is pinned.
        onShown(
            entry: { tabs, entry in
                if tabs.isPinned(entry) { tabs.release(entry: entry) } else { tabs.pin(entry: entry) }
            },
            tab: { tabs, item in tabs.pin(item: item) }
        )
    }

    /// Keeps the tab the acting window shows in the Favorites; takes the favourite it shows out, as a tab; makes the
    /// pinned entry it shows a favourite.
    func toggleFavorite() {
        onShown(
            entry: { tabs, entry in
                if tabs.isPinned(entry) { tabs.favorite(pinned: entry) } else { tabs.release(entry: entry) }
            },
            tab: { tabs, item in tabs.keep(item: item) }
        )
    }

    /// Does `entry` with the kept entry the acting window shows, or `tab` with its tab, animated as the window's moves are.
    private func onShown(
        entry: (TabsModel, Favorites.NodeID) -> Void,
        tab: (TabsModel, Workspace.ItemID) -> Void
    ) {
        guard let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) else { return }
        withAnimation(ShellSettings(AppConfiguration.shared.configuration).layout.smooth) {
            if let shown = tabs.workspace.selectedEntry {
                entry(tabs, shown)
            } else if let item = tabs.workspace.selectedID {
                tab(tabs, item)
            }
        }
    }
}
