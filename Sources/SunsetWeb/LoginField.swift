package import CoreGraphics
package import Foundation

/// A sign-in field that took the keyboard (roadmap 0094): what it is, where it is in the page's view, and the origin of
/// its frame as WebKit says it (never what the page says).
package struct LoginField: Equatable, Sendable {
    package enum Role: String, Sendable { case username, password, newPassword }

    package var role: Role
    package var frame: CGRect
    package var origin: URL
    /// A new password's field: the page's `passwordrules`, when it says any.
    package var rules: String?
}
