import SunsetPane

/// Where a content is, for what it asks (S-e): the Space whose tabs or kept entries hold it.
extension SpacesModel {
    /// The Space whose tabs or kept entries (Space-owned Favorites, profile Favorites, or Pinned grid) hold `content`;
    /// prefers a Space a window currently shows when several share the profile; nil when no Space of the app holds it.
    /// - Parameter content: a pane's content.
    /// - Returns: its Space, or nil.
    package func space(holding content: any PaneContent) -> SpaceModel? {
        if let own = spaces.first(where: { space in
            space.contents.values.contains { $0 === content }
                || (space.ownsFavorites && space.favorites.contents.values.contains { $0 === content })
        }) {
            return own
        }
        let matching = spaces.filter { space in
            let profile = profiles.profile(of: space.space)
            let inProfileFavorites =
                !space.ownsFavorites && profile.favorites.contents.values.contains { $0 === content }
            let inPinned = profile.pinned.contents.values.contains { $0 === content }
            return inProfileFavorites || inPinned
        }
        return matching.first { $0.viewerCount > 0 } ?? matching.first
    }
}
