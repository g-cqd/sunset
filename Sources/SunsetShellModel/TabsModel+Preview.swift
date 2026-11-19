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

    /// What a pane not made yet is saved as (an open entry back from the session, a tab not shown since): its preview names
    /// and pictures it from this (roadmap 0047 I).
    package func pendingDescriptor(_ pane: PaneID) -> PaneDescriptor? {
        guard content(pane) == nil else { return nil }
        return space.pending[pane] ?? favorites.pending[pane] ?? pinned?.pending[pane]
    }

    /// Whether a kept entry runs now: open, and each of its panes made and loaded. Open but not made (back from the session),
    /// it is not drawn as loaded (roadmap 0047 I).
    package func isLoaded(entry: Favorites.Entry) -> Bool {
        guard let open = entry.open else { return false }
        return open.panes.allSatisfy { content($0).map { !$0.isUnloaded } ?? false }
    }
}
