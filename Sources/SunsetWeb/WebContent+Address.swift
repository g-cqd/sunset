package import AppKit
package import SunsetShell
import WebKit

/// What the address bar does with the page's address (roadmap 0047 F).
extension WebContent {
    /// Puts the page's whole address on `board`, as text and as a link; blocked when the page has none.
    @discardableResult
    package func copyAddress(to board: NSPasteboard = .general) -> ActionFeedback {
        guard let address = url?.absoluteString else { return .blocked("This page has no address") }
        return Clipboard.copy(address, isLink: true, what: "Copied the address", to: board)
    }

    package var isBlankPage: Bool { url == nil && webView?.url == nil }

    package func leaveAddressToBar() { addressToBar = true }

    /// What a page adds to its tab's menu: Reload, Copy Address, and its site's settings, shown beside its address.
    package var menuActions: [PaneMenuAction] {
        guard url != nil else { return [] }
        return [
            PaneMenuAction("Reload Page") { [weak self] in self?.reload() },
            reloadAsAction,
            PaneMenuAction("Copy Address") { [weak self] in if let self { Feedback.give(copyAddress()) } },
            PaneMenuAction("Site Settings\u{2026}") { [weak self] in self?.showsSiteSettings = true }
        ]
        .compactMap(\.self)
    }
}
