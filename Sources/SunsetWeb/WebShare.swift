package import CoreGraphics
package import Foundation

/// The app's side (set by it): the tabs a page may be offered, and a tab's feed.
@MainActor
package enum WebShare {
    package static var sources: (_ asking: WebContent) -> [ShareSource] = { _ in [] }
    package static var feed: (_ id: UUID) -> ShareFeed? = { _ in nil }
    /// A small picture of an open tab for the share panel (the owner's note n72): nil for a tab not drawn yet (a page
    /// never loaded, a terminal never shown). Nothing is shared by it.
    package static var preview: @MainActor (_ id: UUID) async -> CGImage? = { _ in nil }
    /// macOS's picker of a screen, a window or an app, and what is picked captured (ADR-0085); nil when cancelled.
    package static var pickSystem: @MainActor () async -> ShareFeed? = { nil }
    /// Other profiles' tabs offered too (`web.shareOtherProfiles`).
    package static var otherProfiles = false
    /// The shares running now, in every page.
    package internal(set) static var sessions: [ShareSession] = []
}
