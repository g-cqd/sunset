package import Foundation

/// A fully private window (n100): a Space of its own, empty, never saved; no Favorites of the app's and no Pinned grid,
/// so that nothing the person keeps in their own windows shows, or opens, in it.
extension TabsModel {
    /// Makes this window, as it starts, a private one: its pages in `group` (shared among its pages when `shares`).
    package func becomePrivate(group: UUID, shares: Bool) {
        privateGroup = group
        privateShares = shares
        space = SpaceModel(favorites: FavoritesModel())
        pinned = nil
    }
}
