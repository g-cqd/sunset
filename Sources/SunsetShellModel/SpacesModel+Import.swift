package import SunsetPane

/// Another browser's bookmarks brought in: in one folder named after where they come from, in a Space that is or one
/// made for them.
extension SpacesModel {
    /// Puts `imported`'s nodes in a new folder `folder` at the end of the Favorites of `target`, or of a new Space named
    /// `newSpace` when `target` is nil. A Space whose Favorites are its profile's shares them with that profile's Spaces.
    /// - Returns: the Space they went to.
    @discardableResult
    package func importFavorites(_ imported: Favorites, folder: String, into target: SpaceModel?, newSpace: String)
        -> SpaceModel
    {
        let space =
            target
            ?? {
                var draft = newDraft()
                draft.name = newSpace
                return add(from: nil, as: draft)
            }()
        space.favorites.edit { $0.append([Favorites.newFolder(named: folder, children: imported.nodes)]) }
        onChange()
        return space
    }
}
