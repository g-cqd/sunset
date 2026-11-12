import AppKit
import Foundation
import SunsetPane
import SunsetShell
import SunsetWeb

/// The History menu's and panel's actions (web step e).
extension AppActions {
    private var keyWindowTabs: TabsModel? { TabRegistry.shared.tabs(for: NSApp.keyWindow) }

    /// Cmd-Y: the history panel on the side opposite the tabs, shown or hidden (`show`: shown).
    func toggleHistoryPanel(show: Bool? = nil) {
        guard let tabs = keyWindowTabs else { return }
        tabs.showsHistory = show ?? !tabs.showsHistory
    }

    func clearHistory() { keyWindowTabs?.clearingHistory = true }

    /// A page of the history: in the focused page, or a new page tab (asked for, or when a terminal has the keyboard).
    func openFromHistory(_ address: String, newTab: Bool) {
        guard let tabs = keyWindowTabs, let url = URL(string: address) else { return }
        WebGo.open(.address(url, guessed: false), in: tabs, place: newTab ? .newTab : .here)
    }
}
