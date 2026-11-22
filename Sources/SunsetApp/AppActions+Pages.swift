import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetWeb
import SunsetWebModel

extension AppActions {
    /// Links to pages handed over by the system: each a page in a new tab of the window in front, or of the first
    /// window once there is one. With the web off, they go to the next app that opens them.
    func open(pages: [URL]) {
        let configuration = AppConfiguration.shared.configuration
        switch IncomingLinks.place(peek: configuration.web.peekLinks, webOn: AppScopes.current.web) {
            case .systemBrowser:
                for page in pages { NSWorkspace.shared.open(page) }
                return
            case .peek:
                // A peek window each, titled with the Space of the window in front.
                let space = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.space.space.id
                for page in pages {
                    let content = WebContent(url: page, settings: PaneContentKinds.webSettings(from: configuration.web))
                    PopupWindowStore.shared.open(content, openerSpace: space, kind: .peek)
                }
                NSApp.activate()
                return
            case .tab: break
        }
        guard let tabs = incomingTabs(alreadyAsked: !pendingPages.isEmpty || !pendingFiles.isEmpty) else {
            pendingPages += pages
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
