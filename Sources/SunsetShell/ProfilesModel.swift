import Foundation
package import Observation
package import SunsetPane

/// The profiles of the app (R4; roadmap 0021, P-a; ADR-0053): the first, always there, and the ones made after. A Space
/// that names no profile, or one that is gone, is of the first.
@MainActor @Observable
package final class ProfilesModel {
    package private(set) var profiles: [ProfileModel]
    @ObservationIgnored private let makeFavorites: @MainActor () -> FavoritesModel
    @ObservationIgnored package var onChange: () -> Void = {}

    /// - Parameters:
    ///   - firstPinned: the first profile's Pinned grid; a new one by default.
    ///   - makeFavorites: the grid of each profile made later.
    package init(firstPinned: FavoritesModel? = nil, makeFavorites: @escaping @MainActor () -> FavoritesModel) {
        self.makeFavorites = makeFavorites
        profiles = [ProfileModel(profile: .first, pinned: firstPinned ?? makeFavorites())]
    }

    package var first: ProfileModel { profiles[0] }
    package func profile(_ id: Profile.ID?) -> ProfileModel { profiles.first { $0.profile.id == id } ?? first }
    package func profile(of space: Space) -> ProfileModel { profile(space.profile) }

    /// A new profile after the others: "Profile N".
    @discardableResult
    package func add() -> ProfileModel {
        var number = profiles.count + 1
        while profiles.contains(where: { $0.profile.name == "Profile \(number)" }) { number += 1 }
        let made = ProfileModel(profile: Profile(name: "Profile \(number)"), pinned: makeFavorites())
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

    /// Takes a profile off the list and closes what is pinned in it; the first stays. The Spaces are the caller's.
    func remove(_ profile: ProfileModel) -> Bool {
        guard profile !== first, let index = profiles.firstIndex(where: { $0 === profile }) else { return false }
        profile.pinned.closeAll()
        profiles.remove(at: index)
        onChange()
        return true
    }

    // MARK: Session

    package func saved() -> [SavedProfile] {
        profiles.map { SavedProfile(profile: $0.profile, pinned: $0.pinned.saved()) }
    }

    /// Takes the saved profiles, before any window: the first's name and grid, then the others in their order.
    package func restore(_ saved: [SavedProfile], reopening: Bool) {
        for one in saved {
            if one.profile.isFirst {
                first.profile = one.profile
                first.pinned.restore(one.pinned, reopening: reopening)
            } else if !profiles.contains(where: { $0.profile.id == one.profile.id }) {
                let made = ProfileModel(profile: one.profile, pinned: makeFavorites())
                made.pinned.restore(one.pinned, reopening: reopening)
                profiles.append(made)
            }
        }
    }
}
