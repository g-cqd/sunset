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
                // A peek window each, titled with the Space of the window in front and using its profile's settings/store.
                let acting = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
                let space = acting?.space.space.id
                let settings =
                    acting.map { PaneContentKinds.webSettings(for: $0) }
                    ?? PaneContentKinds.pageSettings(profile: nil, privacy: nil)
                for page in pages {
                    let content = WebContent(url: page, settings: settings)
                    PopupWindowStore.shared.open(content, openerSpace: space, kind: .peek)
                }
                if configuration.web.focusOpenedTabOrPeek { NSApp.activate() }
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
                tabs.newTab(descriptor, show: configuration.web.focusOpenedTabOrPeek)
            } else {
                newTab(kind: descriptor)
            }
        }
        if configuration.web.focusOpenedTabOrPeek { NSApp.activate() }
    }

    /// The links asked for before a window was there, in the first window.
    func openPendingPages(in tabs: TabsModel) {
        guard !pendingPages.isEmpty else { return }
        let pages = pendingPages
        pendingPages = []
        for page in pages { tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": page.absoluteString])) }
    }
}
