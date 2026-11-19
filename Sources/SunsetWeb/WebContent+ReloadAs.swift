import AppKit
package import Foundation
package import SunsetShell
import WebKit

/// Reload as (roadmap 0050 D): the same tab, where it is, loaded again with another profile's data and settings, a mark on
/// it; reloaded as its Space's profile again, the mark goes. Kept in the session (`as`).
extension WebContent {
    /// Loads the page again as `profile` (nil: the first).
    package func reload(as profile: UUID?) {
        guard !isPrivate, profile != settings.profile else { return }
        let address = webView?.url ?? url
        endView(keepingHistory: true)
        url = address
        takeProfile(profile)
        isUnloaded = address != nil
        // Shown, it is made again at once with the other profile's store.
        if shown, address != nil {
            makeWebView(configuration: nil)
            isUnloaded = false
        }
        onChange()
    }

    /// The profile's settings and store from now on; the mark while it is not its Space's.
    func takeProfile(_ profile: UUID?) {
        if homeProfile == nil { homeProfile = OtherProfile(id: settings.profile) }
        settings = WebProfiles.settings(profile, settings)
        settings.profile = profile
        reloadedAs = homeProfile?.id == profile ? nil : OtherProfile(id: profile)
        ownPermissions = nil
    }

    /// Reload As: every profile but the one it is loaded as; none with one profile, or for a private page.
    package var reloadAsAction: PaneMenuAction? { reloadAsAction(among: WebProfiles.all()) }

    /// Reload As among `profiles` (every profile, by id and name, in their order).
    func reloadAsAction(among profiles: [(id: UUID?, name: String)]) -> PaneMenuAction? {
        let others = profiles.filter { $0.id != settings.profile }
        guard !isPrivate, url != nil, !others.isEmpty else { return nil }
        return PaneMenuAction(
            "Reload As",
            children: others.map { profile in
                // Only a home kept by a reload: with none, `homeProfile?.id` is nil, which is the first profile's id too.
                let mark = homeProfile.map { $0.id == profile.id } ?? false
                return PaneMenuAction(profile.name + (mark ? " (its Space\u{2019}s)" : "")) { [weak self] in
                    self?.reload(as: profile.id)
                }
            }
        )
    }

    /// The name of the profile it was reloaded as, for its mark.
    package var profileMark: String? {
        guard let reloadedAs else { return nil }
        return WebProfiles.all().first { $0.id == reloadedAs.id }?.name ?? "Another profile"
    }

    /// "as" in the session: a profile's id, or "first".
    package static func savedProfile(_ text: String?) -> OtherProfile? {
        guard let text else { return nil }
        return text == "first" ? OtherProfile(id: nil) : UUID(uuidString: text).map { OtherProfile(id: $0) }
    }
}
