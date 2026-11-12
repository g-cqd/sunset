import AppKit
import SunsetHost
import SunsetPane
import SunsetShell

extension AppActions {
    /// The presentation changed: the terminals move to where the new one keeps them. From one window of tabs (sidebar, built-in bar) to a window each (system
    /// tabs, plain windows) every tab but the first goes to a window of its own; the other way every window's terminal becomes a tab of one window and the
    /// emptied windows close. The programs keep running throughout.
    func reshape(from old: TabPresentation, to new: TabPresentation) {
        if old.hostsTabsInWindow, !new.hostsTabsInWindow {
            spreadTabsIntoWindows(joining: new.usesSystemTabbing)
        } else if !old.hostsTabsInWindow, new.hostsTabsInWindow {
            gatherWindowsIntoTabs()
        }
        if new.usesSystemTabbing, !old.usesSystemTabbing { TabRegistry.shared.actingWindow?.mergeAllWindows(nil) }
    }

    private func spreadTabsIntoWindows(joining group: Bool) {
        for (window, tabs) in TabRegistry.shared.allWindows() where tabs.workspace.allPanes.count > 1 {
            for pane in tabs.workspace.allPanes.dropFirst() {
                if let model = tabs.detach(pane: pane) { handoff.append(model) }
            }
            tabParent = group ? window : nil
            joinsRemaining = group ? handoff.count : 0
            for _ in 0 ..< handoff.count { openTerminalWindow() }
        }
    }

    private func gatherWindowsIntoTabs() {
        let all = TabRegistry.shared.allWindows()
        guard let target = all.first else { return }
        for (window, tabs) in all.dropFirst() {
            for pane in tabs.workspace.allPanes {
                if let model = tabs.detach(pane: pane) { target.tabs.adopt(model) }
            }
            window.close()
        }
        if let first = target.tabs.workspace.items.first?.id { target.tabs.select(item: first) }
    }
}
