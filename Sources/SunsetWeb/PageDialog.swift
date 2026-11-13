package import Foundation

/// A dialog a page asked for (`alert`, `confirm`, `prompt`; roadmap 0029 step 1), waiting in its pane. A page is an untrusted
/// program (white paper §9): what it says is shown as plain text, cut to a length, under its host's name, and it is answered once.
@MainActor
package final class PageDialog: Identifiable {
    package enum Kind: Equatable, Sendable {
        case alert, confirm
        case prompt(defaultText: String)
    }

    package enum Reply: Equatable, Sendable {
        /// OK; with what was typed for a prompt.
        case ok(String?)
        case cancel
    }

    /// Characters of a page's message that are shown; the rest is an ellipsis.
    package static let messageLimit = 2000

    package let id = UUID()
    package let kind: Kind
    package let host: String
    package let message: String
    /// The page asked before: the panel offers to stop its dialogs until the page is left.
    package let offersSilence: Bool
    private var reply: ((Reply) -> Void)?

    init(kind: Kind, host: String, message: String, offersSilence: Bool, reply: @escaping (Reply) -> Void) {
        self.kind = kind
        self.host = host
        self.message =
            message.count > Self.messageLimit ? String(message.prefix(Self.messageLimit)) + "\u{2026}" : message
        self.offersSilence = offersSilence
        self.reply = reply
    }

    /// "news.com says"; a page without a host (a file, about:blank) is "This page".
    package var title: String { host.isEmpty ? "This page says" : "\(host) says" }

    /// Answers once; later answers do nothing.
    package func answer(_ value: Reply) {
        guard let reply else { return }
        self.reply = nil
        reply(value)
    }
}
