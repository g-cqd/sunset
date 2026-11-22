package import AppKit

/// Every copy Sunset makes: the text goes on the pasteboard, and the person is told it did, by the button that asked
/// when it has one, else by the trackpad and VoiceOver.
package enum Clipboard {
    /// Puts `text` on `board` (as a link too when `isLink`, marked as a secret when `concealed`, and then cleared after a
    /// while by `expiry`, the app's by default); blocked when it is empty.
    @MainActor
    @discardableResult
    package static func copy(
        _ text: String?,
        isLink: Bool = false,
        concealed: Bool = false,
        what: String = "Copied",
        to board: NSPasteboard = .general,
        expiry: ClipboardExpiry? = nil
    ) -> ActionFeedback {
        guard let text, !text.isEmpty else { return .blocked("Nothing to copy") }
        board.clearContents()
        board.setString(text, forType: .string)
        if isLink { board.setString(text, forType: .URL) }
        if concealed {
            board.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
            (expiry ?? .shared).secretCopied(to: board)
        }
        return .done(what)
    }

    /// The same, and the outcome given (`Feedback.give`): for a copy from a menu, which shows nothing once closed.
    @MainActor
    @discardableResult
    package static func copyAndSay(_ text: String?, isLink: Bool = false, what: String = "Copied") -> ActionFeedback {
        let outcome = copy(text, isLink: isLink, what: what)
        Feedback.give(outcome)
        return outcome
    }
}
