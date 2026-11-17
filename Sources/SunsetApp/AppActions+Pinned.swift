import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The Pinned grid from the menu bar (roadmap 0021, P-b).
extension AppActions {
    /// Pins the tab the acting window shows, or unpins the pinned entry it shows (it is a tab again).
    func togglePinned() {
        guard let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) else { return }
        let smooth = ShellSettings(AppConfiguration.shared.configuration).layout.smooth
        withAnimation(smooth) {
            if let entry = tabs.workspace.selectedEntry {
                if tabs.isPinned(entry) { tabs.release(entry: entry) }
            } else if let item = tabs.workspace.selectedID {
                tabs.pin(item: item)
            }
        }
    }
}
