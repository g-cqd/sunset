import AppKit
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetWeb

extension AppActions {
    /// Links to pages handed over by the system (note n18): each a page in a new tab of the window in front, or of the first
    /// window once there is one. With the web off, they go to the next app that opens them.
    func open(pages: [URL]) {
        guard AppScopes.current.web else {
            for page in pages { NSWorkspace.shared.open(page) }
            return
        }
        let acting = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
        guard let tabs = acting ?? TabRegistry.shared.allWindows().first?.tabs, !tabs.workspace.isEmpty else {
            let asked = !pendingPages.isEmpty || !pendingFiles.isEmpty
            pendingPages += pages
            if !asked, TabRegistry.shared.allWindows().isEmpty {
                tabParent = nil
                joinsRemaining = 0
                openTerminalWindow()
            }
            return
        }
        for page in pages {
            let descriptor = PaneDescriptor(kind: WebContent.kind, state: ["url": page.absoluteString])
            if AppConfiguration.shared.presentation.hostsTabsInWindow {
                tabs.newTab(descriptor)
            } else {
                newTab(kind: descriptor)
            }
        }
        NSApp.activate()
    }

    /// The links asked for before a window was there, in the first window.
    func openPendingPages(in tabs: TabsModel) {
        guard !pendingPages.isEmpty else { return }
        let pages = pendingPages
        pendingPages = []
        for page in pages { tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": page.absoluteString])) }
    }
}
