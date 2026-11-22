package import Observation
package import SunsetPane

/// A profile while the app runs: what names it, its Pinned grid, and its Favorites, the same in each of its Spaces.
@MainActor @Observable
package final class ProfileModel {
    package internal(set) var profile: Profile
    package let pinned: FavoritesModel
    package let favorites: FavoritesModel

    package init(profile: Profile, pinned: FavoritesModel, favorites: FavoritesModel) {
        self.profile = profile
        self.pinned = pinned
        self.favorites = favorites
    }
}
