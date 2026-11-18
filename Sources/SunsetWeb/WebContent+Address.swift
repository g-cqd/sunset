package import AppKit
package import SunsetShell
import WebKit

/// What the address bar does with the page's address (roadmap 0047 F).
extension WebContent {
    /// Puts the page's whole address on `board`, as text and as a link; false when the page has none.
    @discardableResult
    package func copyAddress(to board: NSPasteboard = .general) -> Bool {
        guard let address = url?.absoluteString else { return false }
        board.clearContents()
        board.setString(address, forType: .string)
        board.setString(address, forType: .URL)
        return true
    }

    package var isBlankPage: Bool { url == nil && webView?.url == nil }

    package func leaveAddressToBar() { addressToBar = true }

    /// What a page adds to its tab's menu: Reload, Copy Address, and its site's settings, shown beside its address.
    package var menuActions: [PaneMenuAction] {
        guard url != nil else { return [] }
        return [
            PaneMenuAction("Reload Page") { [weak self] in self?.reload() },
            PaneMenuAction("Copy Address") { [weak self] in self?.copyAddress() },
            PaneMenuAction("Site Settings\u{2026}") { [weak self] in self?.showsSiteSettings = true }
        ]
    }
}
