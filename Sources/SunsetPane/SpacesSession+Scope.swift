extension SpacesSession {
    /// Whose the Favorites and the Pinned grid are (`spaces.favorites`, `spaces.pinned`; roadmap 0044). The default is how
    /// files were written before the settings: the Favorites and the grid each profile's (ADR-0053, ADR-0055).
    public struct Ownership: Sendable, Equatable {
        /// Each Space has its own Favorites; else the Spaces of a profile share its list.
        public var favoritesBySpace: Bool
        /// One Pinned grid for every profile, the first's; else each profile has its own.
        public var pinnedByApp: Bool

        public init(favoritesBySpace: Bool = false, pinnedByApp: Bool = false) {
            self.favoritesBySpace = favoritesBySpace
            self.pinnedByApp = pinnedByApp
        }
    }

    /// The Favorites made each Space's (roadmap 0044): what a profile kept goes to the first of its Spaces, put together with
    /// what that Space has (`Favorites.merge`); the profile keeps none. A profile with no Space keeps its list.
    static func giveFavorites(of profiles: inout [SavedProfile], to spaces: inout [SavedSpace]) {
        for index in profiles.indices where !profiles[index].favorites.favorites.isEmpty {
            let id = profiles[index].profile.id
            let isFirst = profiles[index].profile.isFirst
            guard
                let target = spaces.firstIndex(where: {
                    $0.space.profile == id || (isFirst && $0.space.profile == nil)
                })
            else { continue }
            spaces[target].favorites = Self.joined(profiles[index].favorites, spaces[target].favorites)
            profiles[index].favorites = SavedFavorites()
        }
    }

    /// One grid for the app (roadmap 0044): the other profiles' grids join the first's, which comes first; they keep none.
    static func joinPinned(of profiles: inout [SavedProfile]) {
        guard let first = profiles.firstIndex(where: \.profile.isFirst) else { return }
        for index in profiles.indices where index != first && !profiles[index].pinned.favorites.isEmpty {
            profiles[first].pinned = Self.joined(profiles[first].pinned, profiles[index].pinned)
            profiles[index].pinned = SavedFavorites()
        }
    }

    /// `first`, with what `second` has that it does not; a pane's state from `first` when both have it.
    private static func joined(_ first: SavedFavorites, _ second: SavedFavorites) -> SavedFavorites {
        var all = first.favorites
        all.merge(second.favorites)
        let contents = first.contents.merging(second.contents) { mine, _ in mine }
        return SavedFavorites(favorites: all, contents: contents)
    }
}
