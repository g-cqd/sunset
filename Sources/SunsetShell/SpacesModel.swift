import Foundation
package import Observation
package import SunsetPane

/// The Spaces of the app (R4; ADR-0045, ADR-0047): in one order, the same for every window. There is always one; until
/// there are two nothing of them shows. A window shows one and can change to another (`TabsModel.show(space:)`).
@MainActor @Observable
package final class SpacesModel {
    package private(set) var spaces: [SpaceModel]
    /// Makes the Favorites of a new Space (the app's save with the session and can seal commands).
    @ObservationIgnored private let makeFavorites: @MainActor () -> FavoritesModel
    /// Something changed that the session file holds.
    @ObservationIgnored package var onChange: () -> Void = {}

    /// - Parameters:
    ///   - first: the one Space there is at the start; a new one, unnamed, by default.
    ///   - makeFavorites: the Favorites of each Space made later.
    package init(first: SpaceModel? = nil, makeFavorites: @escaping @MainActor () -> FavoritesModel) {
        self.makeFavorites = makeFavorites
        spaces = [first ?? SpaceModel(favorites: makeFavorites(), keepsTabs: true)]
    }

    package func index(of space: SpaceModel) -> Int? { spaces.firstIndex { $0 === space } }
    package func space(_ id: Space.ID) -> SpaceModel? { spaces.first { $0.space.id == id } }
    package func contains(_ space: SpaceModel) -> Bool { index(of: space) != nil }

    // MARK: Making, naming, deleting

    /// A new Space after the others, with a copy of the Favorites of `origin` (kept, none open) and no tab (the owner,
    /// 2026-11-17). The Space of before there were several is named then: Home, with a house.
    @discardableResult
    package func add(from origin: SpaceModel?) -> SpaceModel {
        if spaces.count == 1, let first = spaces.first, first.space.name.isEmpty {
            first.rename(to: "Home")
            if first.space.icon == nil { first.setIcon(.symbol("house")) }
        }
        var number = spaces.count + 1
        while spaces.contains(where: { $0.space.name == "Space \(number)" }) { number += 1 }
        let favorites = makeFavorites()
        if let origin {
            favorites.restore(SavedFavorites(favorites: origin.favorites.favorites.copied()), reopening: false)
        }
        let made = SpaceModel(
            // The system has a numbered circle for 0 to 50.
            space: Space(name: "Space \(number)", icon: number <= 50 ? .symbol("\(number).circle") : nil),
            favorites: favorites,
            keepsTabs: spaces.first?.keepsTabs ?? true
        )
        spaces.append(made)
        onChange()
        return made
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
