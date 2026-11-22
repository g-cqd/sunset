package import CoreGraphics
package import Foundation

/// A password sent from a form, with its username: what saving offers to keep; and where its password field was in the
/// page's view, for the offer to point at it.
package struct SentLogin: Equatable, Sendable {
    package var origin: URL
    package var username: String
    package var password: String
    package var frame: CGRect = .zero
}
