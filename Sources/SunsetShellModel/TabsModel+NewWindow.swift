package import SunsetPane

/// Tabs taken to a window of their own (the owner, 2026-11-27): a tab dragged out of every window, or dropped on a window
/// with Option held, opens in a new window of the same Space, with the rest of the selection it is part of. A kept entry
/// leaves the Pinned or the Favorites for Today; a pane leaves its split.
extension TabsModel {
    /// Takes what is dragged from the window it started in, as tabs of Today there: their ids, in order; the drag is over.
    /// That window shows another tab when it showed one of them.
    @discardableResult
    package func takeDraggedForWindow() -> (origin: TabsModel, items: [Workspace.ItemID])? {
        let origin = Self.dragOrigin ?? self
        guard let drag = origin.dragged else { return nil }
        origin.dragged = nil
        if dragged != nil, origin !== self { dragged = nil }
        Self.dragOrigin = nil
        let row: RowTarget
        switch drag {
            case .item(let id): row = .tab(id)
            case .entry(let id): row = .node(id)
            case .pane(let pane):
                guard let item = origin.workspace.item(containing: pane) else {
                    origin.separate(pane: pane)
                    return origin.workspace.item(containing: pane).map { (origin, [$0.id]) }
                }
                guard item.isSplit else {
                    row = .tab(item.id)
                    break
                }
                origin.detachIntoTab(pane)
                return origin.workspace.item(containing: pane).map { (origin, [$0.id]) }
            case .document: return nil
        }
        var items: [Workspace.ItemID] = []
        for taken in origin.rows(actingOn: row) {
            switch taken {
                case .tab(let id): items.append(id)
                case .node(let id): if let released = origin.release(entry: id) { items.append(released) }
            }
        }
        origin.clearMarks()
        guard !items.isEmpty else { return nil }
        // The window it came from shows a tab that stays, when there is one.
        if let shown = origin.workspace.selectedID, items.contains(shown),
            let other = origin.workspace.items.last(where: { !items.contains($0.id) })
        {
            origin.select(item: other.id)
        }
        return (origin, items)
    }

    /// Dragged out of every window: what is dragged opens in a new window of its Space.
    package func openDraggedInNewWindow() {
        guard let taken = takeDraggedForWindow() else { return }
        taken.origin.openInNewWindow(taken.items)
    }
}
