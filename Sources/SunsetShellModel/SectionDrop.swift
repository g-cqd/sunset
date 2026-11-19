package import SunsetPane

/// A place in the sidebar's sections where what is dragged can be dropped (roadmap 0035 A): every tab, of every kind, can go
/// to every section and be put in order there; a folder stays in the Favorites.
package enum SectionDrop: Equatable, Sendable {
    /// In the Pinned grid, at that place (nil: at the end).
    case pinned(at: Int?)
    /// In the Favorites, in a folder or at the top (nil), at that place (nil: at the end).
    case favorites(in: Favorites.NodeID?, at: Int?)
    /// Among Today's tabs, at that place.
    case today(at: Int)
}
