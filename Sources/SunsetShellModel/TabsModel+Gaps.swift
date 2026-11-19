package import SunsetPane

/// The gaps between the sidebar's rows as places to drop (roadmap 0038 B, F): gap k is before the k-th row shown, the last
/// one after them all.
extension TabsModel {
    /// The Favorites' rows as shown: folders, and the entries of open folders, in order; an entry of a scope that is off is not.
    package var favoritesRows: [Favorites.NodeID] {
        let tree = favorites.favorites
        return tree.rows(selected: workspace.selectedEntry)
            .compactMap { row in
                if case .entry(let entry) = tree.node(row.id), !shows(entry) { return nil }
                return row.id
            }
    }

    /// Where gap k of the Favorites puts what is dropped: before the k-th row, in its folder; after the last row, at the end of
    /// the Favorites (their bottom).
    package func favoritesGap(_ k: Int) -> SectionDrop {
        let rows = favoritesRows
        guard k < rows.count, let place = favorites.favorites.location(of: rows[k]) else {
            return .favorites(in: nil, at: nil)
        }
        return .favorites(in: place.parent, at: place.index)
    }
}
