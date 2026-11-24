import Foundation
package import Observation
package import SunsetPane

/// The profiles of the app (P-a): the first, always there, and the ones made after. A Space that names no profile, or
/// one that is gone, is of the first.
@MainActor @Observable
package final class ProfilesModel {
    package private(set) var profiles: [ProfileModel]
    @ObservationIgnored private let makeFavorites: @MainActor () -> FavoritesModel
    /// One Pinned grid for every profile, the first's (`spaces.pinned`).
    package let sharesPinned: Bool
    @ObservationIgnored package var onChange: () -> Void = {}

    /// - Parameters:
    ///   - firstPinned: the first profile's Pinned grid; a new one by default.
    ///   - firstFavorites: the first profile's Favorites; new ones by default.
    ///   - sharesPinned: every profile shows the first's grid.
    ///   - makeFavorites: the grid and the Favorites of each profile made later.
    package init(
        firstPinned: FavoritesModel? = nil,
        firstFavorites: FavoritesModel? = nil,
        sharesPinned: Bool = false,
        makeFavorites: @escaping @MainActor () -> FavoritesModel
    ) {
        self.makeFavorites = makeFavorites
        self.sharesPinned = sharesPinned
        let first = ProfileModel(
            profile: .first,
            pinned: firstPinned ?? makeFavorites(),
            favorites: firstFavorites ?? makeFavorites()
        )
        profiles = [first]
    }

    package var first: ProfileModel {
        profiles[0]
    }
    package func profile(_ id: Profile.ID?) -> ProfileModel {
        profiles.first { $0.profile.id == id } ?? first
    }
    package func profile(of space: Space) -> ProfileModel {
        profile(space.profile)
    }

    /// A new profile after the others: "Profile N".
    @discardableResult
    package func add() -> ProfileModel {
        var number = profiles.count + 1
        while profiles.contains(where: { $0.profile.name == "Profile \(number)" }) { number += 1 }
        let named = Profile(name: "Profile \(number)")
        let made = ProfileModel(profile: named, pinned: newPinned(), favorites: makeFavorites())
        profiles.append(made)
        onChange()
        return made
    }

    /// Names a profile; a blank name is not taken.
    package func rename(_ profile: ProfileModel, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != profile.profile.name else { return }
        profile.profile.name = trimmed
        onChange()
    }

    /// Sets what `profile` sets otherwise than all profiles: only what differs.
    package func setOverrides(_ overrides: [String: String], for profile: ProfileModel) {
        guard overrides != profile.profile.overrides else { return }
        profile.profile.overrides = overrides
        onChange()
    }

    /// Takes a profile off the list and closes what is kept in it (pinned, favourites); the first stays. The Spaces are
    /// the caller's.
    package func remove(_ profile: ProfileModel) -> Bool {
        guard profile !== first, let index = profiles.firstIndex(where: { $0 === profile }) else { return false }
        if profile.pinned !== first.pinned { profile.pinned.closeAll() }
        profile.favorites.closeAll()
        profiles.remove(at: index)
        onChange()
        return true
    }

    // MARK: Session

    /// The profiles as the session file keeps them.
    /// - Parameter favorites: the Favorites are the profiles' (else each Space's, which saves them).
    /// - Returns: each profile, with its grid (a shared one with the first only) and its Favorites.
    package func saved(favorites: Bool = true) -> [SavedProfile] {
        profiles.map {
            SavedProfile(
                profile: $0.profile,
                // A grid shared by all is saved once, with the first.
                pinned: sharesPinned && !$0.profile.isFirst ? SavedFavorites() : $0.pinned.saved(),
                favorites: favorites ? $0.favorites.saved() : SavedFavorites()
            )
        }
    }

    /// Takes the saved profiles, before any window: the first's name and what is kept in it, then the others in order.
    package func restore(_ saved: [SavedProfile]) {
        for one in saved {
            if one.profile.isFirst {
                first.profile = one.profile
                first.pinned.restore(one.pinned)
                first.favorites.restore(one.favorites)
            } else if !profiles.contains(where: { $0.profile.id == one.profile.id }) {
                let made = ProfileModel(profile: one.profile, pinned: newPinned(), favorites: makeFavorites())
                if !sharesPinned { made.pinned.restore(one.pinned) }
                made.favorites.restore(one.favorites)
                profiles.append(made)
            }
        }
    }

    /// The grid of a profile made now: its own, or the first's when one is shared.
    private func newPinned() -> FavoritesModel {
        sharesPinned ? first.pinned : makeFavorites()
    }
}
