import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The Pinned grid from the menu bar (roadmap 0021, P-b).
extension AppActions {
    /// Pins the tab or the favourite the acting window shows, or unpins the pinned entry it shows (it is a tab again).
    func togglePinned() {
        guard let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) else { return }
        let smooth = ShellSettings(AppConfiguration.shared.configuration).layout.smooth
        withAnimation(smooth) {
            if let entry = tabs.workspace.selectedEntry {
                // A pinned entry is a tab again; a favourite is pinned.
                if tabs.isPinned(entry) { tabs.release(entry: entry) } else { tabs.pin(entry: entry) }
            } else if let item = tabs.workspace.selectedID {
                tabs.pin(item: item)
            }
        }
    }

    /// Keeps the tab the acting window shows in the Favorites; takes the favourite it shows out, as a tab; makes the
    /// pinned entry it shows a favourite.
    func toggleFavorite() {
        guard let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) else { return }
        let smooth = ShellSettings(AppConfiguration.shared.configuration).layout.smooth
        withAnimation(smooth) {
            if let entry = tabs.workspace.selectedEntry {
                if tabs.isPinned(entry) { tabs.favorite(pinned: entry) } else { tabs.release(entry: entry) }
            } else if let item = tabs.workspace.selectedID {
                tabs.keep(item: item)
            }
        }
    }
}
