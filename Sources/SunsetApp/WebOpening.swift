import Foundation
import SunsetPane
import SunsetShell
import SunsetWeb

/// Where the pages a page opens go: a tab right after it, not shown; a split beside it; a window of its own.
@MainActor enum WebOpening {
    /// Gives `page` its way of placing what it opens, in the window `tabs`, and of saving what changes.
    static func wire(_ page: WebContent, in tabs: TabsModel) {
        page.onChange = { SessionStore.shared.scheduleSave() }
        page.history = page.isPrivate ? nil : AppHistory.shared
        page.onNotify = { [weak page] note in
            if let page { AppWebNotifications.shared.post(note, from: page) }
        }
        page.onNotificationClose = { [weak page] id in
            if let page { AppWebNotifications.shared.close(id, from: page) }
        }
        page.currentSpace = { [weak tabs] in
            guard let tabs, !tabs.isPrivateWindow, AppSpaces.all.contains(tabs.space) else { return nil }
            return tabs.space.space.id
        }
        page.spaceChoices = {
            AppSpaces.all.spaces.count > 1 ? AppSpaces.all.spaces.map { ($0.space.id, $0.space.name) } : []
        }
        page.openInSpace = { [weak tabs, weak page] url, id in
            // The window goes to the site's Space and opens it there, as that Space's (its profile's logins).
            guard let tabs, page?.currentSpace() != nil, let target = AppSpaces.all.space(id) else { return }
            tabs.show(space: target, in: AppSpaces.all)
            tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": url.absoluteString]))
        }
        page.onOpen = { [weak tabs, weak page] opened, placement in
            guard let tabs, let page else { return }
            wire(opened, in: tabs)
            switch placement {
                case .tabAfter, .privateTab: tabs.insertTab(opened, after: page, show: false)
                case .opened:
                    tabs.insertTab(opened, after: page, show: AppConfiguration.shared.showsOpenedPages)
                case .splitRight: tabs.split(.right, with: opened, beside: page)
                case .splitDown: tabs.split(.bottom, with: opened, beside: page)
                case .window:
                    AppActions.shared.handoff.append(opened)
                    AppActions.shared.openTerminalWindow()
                case .popup:
                    PopupWindowStore.shared.open(opened, openerSpace: page.currentSpace())
            }
        }
    }
}
