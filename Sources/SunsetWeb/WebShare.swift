package import Foundation

/// The app's side (set by it): the tabs a page may be offered, and a tab's feed.
@MainActor
package enum WebShare {
    package static var sources: (_ asking: WebContent) -> [ShareSource] = { _ in [] }
    package static var feed: (_ id: UUID) -> ShareFeed? = { _ in nil }
    /// Other profiles' tabs offered too (`web.shareOtherProfiles`).
    package static var otherProfiles = false
}
