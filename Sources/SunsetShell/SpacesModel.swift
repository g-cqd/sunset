import Foundation
package import Observation
package import SunsetPane

/// The Spaces of the app (R4; ADR-0045, ADR-0047): in one order, the same for every window. There is always one; until
/// there are two nothing of them shows. A window shows one and can change to another (`TabsModel.show(space:)`).
@MainActor @Observable
package final class SpacesModel {
    package private(set) var spaces: [SpaceModel]
    /// The profiles the Spaces belong to.
    package let profiles: ProfilesModel
    /// Makes the Favorites of a new Space (the app's save with the session and can seal commands).
    @ObservationIgnored private let makeFavorites: @MainActor () -> FavoritesModel
    /// Something changed that the session file holds.
    @ObservationIgnored package var onChange: () -> Void = {}

    /// - Parameters:
    ///   - first: the one Space there is at the start; a new one, unnamed, by default.
    ///   - pinned: the first profile's Pinned grid; a new one by default.
    ///   - makeFavorites: the Favorites of each Space, and the grid of each profile, made later.
    package init(
        first: SpaceModel? = nil,
        pinned: FavoritesModel? = nil,
        makeFavorites: @escaping @MainActor () -> FavoritesModel
    ) {
        self.makeFavorites = makeFavorites
        profiles = ProfilesModel(firstPinned: pinned, makeFavorites: makeFavorites)
        spaces = [first ?? SpaceModel(favorites: makeFavorites(), keepsTabs: true)]
    }

    package func index(of space: SpaceModel) -> Int? { spaces.firstIndex { $0 === space } }
    package func space(_ id: Space.ID) -> SpaceModel? { spaces.first { $0.space.id == id } }
    package func contains(_ space: SpaceModel) -> Bool { index(of: space) != nil }

    // MARK: Making, naming, deleting

    /// What the editor of a new Space starts from: "Space N", with a numbered circle (the system has one for 0 to 50).
    package func newDraft() -> SpaceDraft {
        var number = spaces.count + 1
        while spaces.contains(where: { $0.space.name == "Space \(number)" }) { number += 1 }
        return SpaceDraft(space: nil, name: "Space \(number)", icon: number <= 50 ? .symbol("\(number).circle") : nil)
    }

    /// A new Space after the others, with a copy of the Favorites of `origin` (kept, none open) and no tab (the owner,
    /// 2026-11-17). The Space of before there were several is named then: Home, with a house.
    /// - Parameters:
    ///   - origin: the Space whose Favorites are copied.
    ///   - draft: its name, colour and icon; "Space N" with a numbered circle when none is given.
    /// - Returns: the Space made.
    @discardableResult
    package func add(from origin: SpaceModel?, as draft: SpaceDraft? = nil) -> SpaceModel {
        let draft = draft ?? newDraft()
        if spaces.count == 1, let first = spaces.first, first.space.name.isEmpty {
            first.rename(to: "Home")
            if first.space.icon == nil { first.setIcon(.symbol("house")) }
        }
        let favorites = makeFavorites()
        if let origin {
            favorites.restore(SavedFavorites(favorites: origin.favorites.favorites.copied()), reopening: false)
        }
        var named = Space(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), icon: draft.icon)
        named.tint = draft.tint
        named.profile = draft.profile == Profile.firstID ? nil : draft.profile
        let made = SpaceModel(space: named, favorites: favorites, keepsTabs: spaces.first?.keepsTabs ?? true)
        spaces.append(made)
        onChange()
        return made
    }

    /// Gives a Space what its editor was saved with.
    package func apply(_ draft: SpaceDraft, to space: SpaceModel) {
        guard draft.canSave else { return }
        space.rename(to: draft.name.trimmingCharacters(in: .whitespacesAndNewlines))
        space.setIcon(draft.icon)
        space.setTint(draft.tint)
        setProfile(draft.profile, for: space)
        onChange()
    }

    /// Names a Space; a blank name is not taken (a Space among several has a name).
    package func rename(_ space: SpaceModel, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != space.space.name else { return }
        space.rename(to: trimmed)
        onChange()
    }

    package func setIcon(_ icon: PaneIcon?, for space: SpaceModel) {
        space.setIcon(icon)
        onChange()
    }

    /// Puts a Space at another place in the order.
    package func move(_ space: SpaceModel, to index: Int) {
        guard let from = self.index(of: space) else { return }
        spaces.remove(at: from)
        spaces.insert(space, at: min(max(index, 0), spaces.count))
        onChange()
    }

    /// Deletes a Space; the last one stays. What it holds goes to `target`, still running, or closes. The windows that
    /// showed it show `target`, or the Space before it.
    package func remove(_ space: SpaceModel, movingTo target: SpaceModel?) {
        guard spaces.count > 1, let index = index(of: space), target !== space else { return }
        let destination = target ?? spaces[index == 0 ? 1 : index - 1]
        for viewer in space.currentViewers { viewer.show(space: destination) }
        if let target {
            let given = space.giveAll()
            target.adopt(given.items, contents: given.contents, pending: given.pending)
            target.favorites.absorb(space.favorites)
        } else {
            space.closeAll()
            space.favorites.closeAll()
        }
        spaces.remove(at: index)
        onChange()
    }

    /// Where what a deleted Space holds can go: the Space before it, or the one after the first.
    package func neighbour(of space: SpaceModel) -> SpaceModel? {
        guard spaces.count > 1, let index = index(of: space) else { return nil }
        return spaces[index == 0 ? 1 : index - 1]
    }

    // MARK: Profiles

    package func spaces(of profile: ProfileModel) -> [SpaceModel] {
        spaces.filter { profiles.profile(of: $0.space) === profile }
    }

    /// Gives a Space a profile (nil, or the first's id: the first). Its windows show that profile's Pinned grid, and what
    /// its pages are made with is the caller's to make again (`SpaceModel.restart`).
    package func setProfile(_ id: Profile.ID?, for space: SpaceModel) {
        let wanted = id == Profile.firstID ? nil : id
        guard space.space.profile != wanted else { return }
        space.setProfile(wanted)
        for viewer in space.currentViewers { viewer.followProfile() }
        onChange()
    }

    /// Removes a profile: its Spaces are of the first from now on, and what was pinned in it is closed. The first stays.
    /// - Returns: its id, for its website data to be erased; nil when nothing was removed.
    @discardableResult
    package func remove(profile: ProfileModel) -> Profile.ID? {
        let its = spaces(of: profile)
        guard profiles.remove(profile) else { return nil }
        for space in its { setProfile(nil, for: space) }
        for space in spaces { for viewer in space.currentViewers { viewer.followProfile() } }
        return profile.profile.id
    }

    // MARK: Windows

    /// A window closed. With none left on any Space, every Space stops: the ones left by changing ran on until now.
    func windowClosed(at date: Date) {
        guard spaces.allSatisfy({ $0.viewerCount == 0 }) else { return }
        for space in spaces { space.stopIfUnshown(at: date) }
    }

    /// Whether the tabs of each Space stay when its last window closes (`tabs.closeWithLastWindow`).
    package func keepTabs(_ keeps: Bool) { for space in spaces { space.keepsTabs = keeps } }

    // MARK: Session

    package func saved() -> [SavedSpace] { spaces.map { $0.saved() } }

    /// Takes the saved Spaces, in their order, before any window shows one: the first is the one there was.
    package func restore(_ saved: [SavedSpace], reopening: Bool) {
        guard let first = saved.first, spaces.count == 1 else { return }
        spaces[0].restore(first, reopening: reopening)
        for other in saved.dropFirst() {
            let space = SpaceModel(space: other.space, favorites: makeFavorites(), keepsTabs: spaces[0].keepsTabs)
            space.restore(other, reopening: reopening)
            spaces.append(space)
        }
    }
}
