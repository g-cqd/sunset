import AppKit
import SunsetHost

/// The system's tabbing for a window, as the presentation says (apple-docs: `NSWindow.tabbingMode`, `tabbingIdentifier`, `tabGroup`, `toggleTabBar(_:)`,
/// `moveTabToNewWindow(_:)`). Windows with the same `tabbingIdentifier` and `.preferred` join one tab group; `.disallowed` keeps a window alone.
extension ChromeView {
    static let tabbingIdentifier: NSWindow.TabbingIdentifier = "sunset.terminal"

    func applyTabbing(to window: NSWindow) {
        window.tabbingIdentifier = Self.tabbingIdentifier
        let wanted: NSWindow.TabbingMode = presentation.usesSystemTabbing ? .preferred : .disallowed
        if window.tabbingMode != wanted { window.tabbingMode = wanted }
        guard let group = window.tabGroup, group.windows.count > 1 else { return }
        if !presentation.usesSystemTabbing {
            // Leaving system tabs: every tab but this one goes back to a window of its own (the programs keep running).
            for other in group.windows where other !== window { other.moveTabToNewWindow(nil) }
            return
        }
        Self.syncTabBar(of: window, presentation: presentation)
    }

    /// The sidebar shows the tabs, so the system's own bar is hidden; with the bar presentation it is shown (`NSWindowTabGroup.isTabBarVisible`).
    static func syncTabBar(of window: NSWindow, presentation: TabPresentation) {
        guard let group = window.tabGroup, group.windows.count > 1, presentation.usesSystemTabbing else { return }
        if group.isTabBarVisible != presentation.showsNativeTabBar { window.toggleTabBar(nil) }
    }
}
