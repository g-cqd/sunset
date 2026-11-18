import Foundation

/// What a click did, said back to the person (the owner's note n11): it went through, or it was blocked and why. A button
/// shows it for a moment (a check, or a shake and a cross), the trackpad answers where it can, and VoiceOver says it.
package enum ActionFeedback: Equatable, Sendable {
    /// Done: what is said ("Copied").
    case done(String)
    /// Not done: why ("This page has no address").
    case blocked(String)

    /// How long a button shows it.
    package static let shown: Duration = .milliseconds(1200)

    /// The symbol a button shows in place of its own while it does.
    package var symbol: String {
        switch self {
            case .done: "checkmark"
            case .blocked: "xmark"
        }
    }

    /// What VoiceOver says.
    package var announcement: String {
        switch self {
            case .done(let said), .blocked(let said): said
        }
    }

    package var isDone: Bool {
        if case .done = self { return true }
        return false
    }
}
