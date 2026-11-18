import SunsetPane

/// Whose the Favorites are (roadmap 0044): each Space's own, or its profile's (ADR-0055).
extension SpacesModel {
    /// The Favorites a Space that is made or read shows: new ones of its own, or its profile's.
    func favorites(for space: Space) -> FavoritesModel {
        ownership.favoritesBySpace ? makeFavorites() : profiles.profile(of: space).favorites
    }

    /// Gives a Space what was saved of its Favorites, when they are its own; else it shows its profile's.
    func restoreFavorites(of space: SpaceModel, from saved: SavedSpace, reopening: Bool) {
        guard space.ownsFavorites else {
            space.favorites = profiles.profile(of: space.space).favorites
            return
        }
        space.favorites.restore(saved.favorites, reopening: reopening)
    }

    /// A Space is deleted: its own Favorites go, still running, to the end of `target`'s; with no target they close.
    func giveFavorites(of space: SpaceModel, to target: SpaceModel?) {
        guard space.ownsFavorites else { return }
        guard let target, target.favorites !== space.favorites else { return space.favorites.closeAll() }
        for node in space.favorites.favorites.nodes {
            switch node {
                case .entry(let entry): _ = space.favorites.give(entry.id, to: target.favorites)
                case .folder: break
            }
        }
        // Folders go as they are, put together with the target's; what was open in them closes here.
        var left = space.favorites.favorites
        left.unloadAll()
        if !left.isEmpty { target.favorites.edit { $0.merge(left) } }
        space.favorites.closeAll()
    }
}
