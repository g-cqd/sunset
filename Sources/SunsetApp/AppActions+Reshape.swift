import AppKit
import SunsetHost

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
        if new.usesSystemTabbing, !old.usesSystemTabbing { NSApp.keyWindow?.mergeAllWindows(nil) }
    }

    private func spreadTabsIntoWindows(joining group: Bool) {
        for (window, tabs) in TabRegistry.shared.allWindows() where tabs.list.count > 1 {
            for tab in tabs.list.tabs.dropFirst() {
                if let model = tabs.detach(tab.id) { handoff.append(model) }
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
            for tab in tabs.list.tabs {
                if let model = tabs.detach(tab.id) { target.tabs.adopt(model) }
            }
            window.close()
        }
        if let first = target.tabs.list.tabs.first?.id { target.tabs.select(first) }
    }
}
