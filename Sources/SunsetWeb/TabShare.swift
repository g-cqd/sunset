package import Foundation

/// The rules of a share (ADR-0082, white paper §9).
package enum TabShare {
    /// The tabs a page of `profile` may be offered: its own profile's, every profile's with `otherProfiles`.
    package static func offered(_ all: [ShareSource], to profile: UUID?, otherProfiles: Bool) -> [ShareSource] {
        otherProfiles ? all : all.filter { $0.profile == profile }
    }

    /// Why a running share stops, or nil while it goes on.
    package enum Stop: Equatable, Sendable { case sourceClosed, requesterClosed, sourceLeftSite, stopped }

    /// Whether the share from `source` (started on `startHost`) goes on, given what is the case now.
    package static func stop(
        sourceOpen: Bool,
        requesterOpen: Bool,
        startHost: String?,
        hostNow: String?,
        stoppedByPerson: Bool
    ) -> Stop? {
        if stoppedByPerson { return .stopped }
        if !sourceOpen { return .sourceClosed }
        if !requesterOpen { return .requesterClosed }
        if let startHost, let hostNow, !SitePattern.site(SiteHost.key(startHost)).matches(host: hostNow) {
            return .sourceLeftSite
        }
        return nil
    }
}
