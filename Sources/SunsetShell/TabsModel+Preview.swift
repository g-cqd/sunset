package import SunsetPane

/// What the hover card shows (the owner, 2026-11-17: "no preview on loaded favorites tabs or pinned tabs"): the row under the
/// pointer is a tab of Today or an open kept entry, named by its tab's id (`hoveredItem`).
extension TabsModel {
    /// The tab the hover card would show for `id`: Today's, else an open favourite's or tile's; nil when there is none.
    package func previewItem(_ id: Workspace.ItemID) -> Workspace.Item? {
        if let item = workspace.items.first(where: { $0.id == id }) { return item }
        for keeper in [favorites, pinned].compactMap({ $0 }) {
            if let open = keeper.favorites.entries.lazy.compactMap(\.open).first(where: { $0.id == id }) { return open }
        }
        return nil
    }

    /// What a kept entry's row sets `hoveredItem` to: its open tab's id; nil when it is not loaded (nothing to show).
    package func hoverID(entry id: Favorites.NodeID) -> Workspace.ItemID? {
        keeper(of: id).favorites.entry(id)?.open?.id
    }
}
