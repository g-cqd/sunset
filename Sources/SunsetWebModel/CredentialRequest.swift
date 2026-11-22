package import Foundation

/// A server asking for a name and a password (HTTP Basic or Digest), waiting in the page's pane. What the server calls
/// itself (its realm) is shown as plain text, cut; the host is the one the connection goes to.
@MainActor
package final class CredentialRequest: Identifiable {
    package struct Answer: Equatable, Sendable {
        package var user: String
        package var password: String

        package init(
            user: String,
            password: String
        ) {
            self.user = user
            self.password = password
        }
    }

    package static let realmLimit = 80

    package let id = UUID()
    package let host: String
    package let realm: String
    /// What to say besides: the last answer was refused, or the password goes in the clear.
    package let warning: String?
    private var reply: ((Answer?) -> Void)?

    package init(host: String, realm: String, failed: Bool, secure: Bool, reply: @escaping (Answer?) -> Void) {
        self.host = host
        let clean = UntrustedText.oneLine(realm)
        self.realm = clean.count > Self.realmLimit ? String(clean.prefix(Self.realmLimit)) + "\u{2026}" : clean
        warning =
            failed
            ? "That name or password was not accepted."
            : secure ? nil : "The password will be sent without encryption."
        self.reply = reply
    }

    package var title: String {
        "Sign in to \(host)"
    }

    /// Answers once (nil cancels); later answers do nothing.
    package func answer(_ value: Answer?) {
        guard let reply else { return }
        self.reply = nil
        reply(value)
    }
}
