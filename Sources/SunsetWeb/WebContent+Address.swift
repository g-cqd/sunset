package import AppKit

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
}
