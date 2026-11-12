import SunsetPane
import SunsetShell
import SunsetWeb

/// Where the pages a page opens go (R1, web step a): a tab right after it, not shown; a split beside it; a window of its own.
@MainActor enum WebOpening {
    /// Gives `page` its way of placing what it opens, in the window `tabs`, and of saving what changes.
    static func wire(_ page: WebContent, in tabs: TabsModel) {
        page.onChange = { SessionStore.shared.scheduleSave() }
        page.history = page.isPrivate ? nil : AppHistory.shared
        page.onOpen = { [weak tabs, weak page] opened, placement in
            guard let tabs, let page else { return }
            wire(opened, in: tabs)
            switch placement {
                case .tabAfter, .privateTab: tabs.insertTab(opened, after: page, show: false)
                case .splitRight: tabs.split(.right, with: opened, beside: page)
                case .splitDown: tabs.split(.bottom, with: opened, beside: page)
                case .window:
                    AppActions.shared.handoff.append(opened)
                    AppActions.shared.openTerminalWindow()
            }
        }
    }
}
