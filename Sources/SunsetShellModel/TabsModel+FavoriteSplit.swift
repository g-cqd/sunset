package import SunsetPane

/// A tab dropped on a favorite's row (the owner's note n84): its middle splits with the favorite, which leaves the
/// Favorites as a tab, as a favorite dropped on a tab's row does; its top and bottom quarters put it before or after.
extension TabsModel {
    /// Whether what is dragged can be dropped on the favorite `entry` with `action`.
    package func canDrop(onEntry entry: Favorites.NodeID, action: TabDropAction) -> Bool {
        guard case .split = action else { return canDrop(onEntry: entry) }
        adoptDrag()
        // A favorite, not a pinned tile nor a folder.
        guard favorites.favorites.entry(entry) != nil, !isPinned(entry) else { return false }
        return switch dragged {
            case .item, .pane, .document: true
            case .entry(let id): id != entry && !isPinned(id)
            case nil: false
        }
    }

    /// Drops what is dragged on the favorite `entry` with `action`.
    @discardableResult
    package func dropDragged(onEntry entry: Favorites.NodeID, action: TabDropAction) -> Bool {
        guard case .split = action else { return dropDragged(onEntry: entry, after: action == .moveAfter) }
        guard canDrop(onEntry: entry, action: action), let released = release(entry: entry) else { return false }
        return dropDragged(onto: released, action: action)
    }
}
