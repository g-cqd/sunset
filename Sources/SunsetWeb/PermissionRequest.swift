package import Foundation

/// A page waiting for an answer (web step g): what it wants, from which site, and how to answer it. Shown as the panel under its address.
@MainActor
package final class PermissionRequest: Identifiable {
    package enum Choice { case allowOnce, allow, deny }

    package let id = UUID()
    package let permissions: [SitePermission]
    package let host: String
    /// Set when Sunset cannot pass the request on to macOS (it runs without Sunset.app's identity): the panel says so and only closes.
    package let unavailable: Bool
    private var answer: ((Bool) -> Void)?

    init(permissions: [SitePermission], host: String, unavailable: Bool = false, answer: @escaping (Bool) -> Void) {
        self.permissions = permissions
        self.host = host
        self.unavailable = unavailable
        self.answer = answer
    }

    /// What the panel says: "meet.com wants to use your camera and use your microphone."
    package var sentence: String {
        let wants = permissions.map(\.request)
        let joined =
            wants.count > 1
            ? wants.dropLast().joined(separator: ", ") + " and " + wants[wants.count - 1] : wants.first ?? ""
        return "\(host) wants to \(joined)."
    }

    /// Answers once; Allow and Don't Allow are kept for the site.
    package func choose(_ choice: Choice, keepIn store: SitePermissions) {
        guard let answer else { return }
        self.answer = nil
        if choice != .allowOnce, !unavailable {
            for permission in permissions { store.set(choice == .allow ? .allow : .deny, permission, for: host) }
        }
        answer(choice != .deny && !unavailable)
    }
}
