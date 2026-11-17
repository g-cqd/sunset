package import Observation
package import SunsetPane

/// A profile while the app runs (R4; ADR-0053): what names it, and its Pinned grid.
@MainActor @Observable
package final class ProfileModel {
    package internal(set) var profile: Profile
    package let pinned: FavoritesModel

    init(profile: Profile, pinned: FavoritesModel) {
        self.profile = profile
        self.pinned = pinned
    }
}
