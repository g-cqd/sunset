package import Foundation
package import SunsetPane

extension TabsModel {
    // MARK: Dragging

    /// What a drag of a tab or a pane carries (as text). Called when the drag starts, not when the row is drawn: it remembers what is being dragged, so that
    /// the drop areas can tell at once what would happen.
    package func itemProvider(for payload: PaneDragPayload) -> NSItemProvider {
        dragged = payload
        Self.dragOrigin = self
        return NSItemProvider(object: payload.text as NSString)
    }

    /// Whether what is dragged could be dropped on a pane: a pane not on itself; a tab on another tab's pane, or on its own when there is another tab to ask for
    /// (`choice`).
    package func canDrop(onto pane: PaneID) -> Bool {
        adoptDrag()
        let inKeptEntry = keeper(ofPane: pane)?.favorites.entry(containing: pane)
        return switch dragged {
            case .item(let id):
                if inKeptEntry != nil {
                    true
                } else {
                    workspace.item(containing: pane)?.id != id || workspace.count > 1
                }
            case .pane(let id): id != pane
            case .document: true
            // When `pane` belongs to a kept entry (Favorite or Pinned), another kept entry splits into it in place.
            // When `pane` belongs to Today's tabs, a favorite or a pinned tab leaves for Today and splits with it (the
            // owner, 2026-11-27: a pinned tab offered no split over the window).
            case .entry(let id):
                if let target = inKeptEntry { target.id != id } else { keeper(of: id).favorites.entry(id) != nil }
            case nil: false
        }
    }

    /// Drops what is dragged on `edge` of a pane (the tab joins that pane's tab or kept entry, or the pane moves beside it).
    @discardableResult
    package func dropDragged(onto pane: PaneID, edge: PaneEdge) -> Bool {
        guard canDrop(onto: pane) else { return false }
        bringDraggedHere()
        // If `pane` is inside an open Favorite or Pinned entry, split in place inside that entry instead of releasing to Today!
        if let targetModel = keeper(ofPane: pane), let targetEntry = targetModel.favorites.entry(containing: pane) {
            if case .pane(let draggedPane) = dragged, targetEntry.open?.panes.contains(draggedPane) == true {
                guard let content = targetModel.separate(pane: draggedPane) else { return false }
                dragged = nil
                guard
                    targetModel.insertLayout(
                        .pane(draggedPane),
                        focused: draggedPane,
                        beside: pane,
                        edge: edge,
                        contents: [draggedPane: content]
                    )
                else { return false }
                showEntry(targetEntry.id)
                return true
            }
            guard let extracted = takeDraggedForEntrySplit(excluding: targetEntry.id) else { return false }
            dragged = nil
            guard
                targetModel.insertLayout(
                    extracted.layout,
                    focused: extracted.focused,
                    beside: pane,
                    edge: edge,
                    contents: extracted.contents
                )
            else { return false }
            showEntry(targetEntry.id)
            return true
        }
        takeDocumentDrag()
        guard var drag = dragged else { return false }
        dragged = nil
        // A favorite leaves the Favorites as a tab first, then joins the pane's tab as a tab would.
        if case .entry(let entry) = drag {
            guard let released = release(entry: entry) else { return false }
            drag = .item(released)
        }
        switch drag {
            case .item(let id) where workspace.item(containing: pane)?.id == id:
                bar = CommandBar(purpose: .splitWith(SplitChoice(pane: pane, edge: edge)))
            case .item(let id): drop(item: id, onto: pane, edge: edge)
            case .pane(let id): movePane(id, beside: pane, edge: edge)
            case .entry, .document: return false
        }
        return true
    }

    package func complete(_ choice: SplitChoice, with other: Workspace.ItemID) {
        change {
            $0.drop(item: other, onto: choice.pane, edge: choice.edge.opposite)
            $0.focus(pane: choice.pane)
        }
    }

    /// Whether what is dragged can be dropped on the tab row `item` with `action`.
    package func canDrop(onto item: Workspace.ItemID, action: TabDropAction) -> Bool {
        adoptDrag()
        switch (dragged, action) {
            case (.item(let id), _):
                return id != item
            case (.pane(let pane), .split):
                return workspace.item(containing: pane)?.focused != pane || workspace.item(containing: pane)?.id != item
            case (.pane(let pane), .moveBefore), (.pane(let pane), .moveAfter):
                // The pane of a split's row carries the split.
                guard let source = workspace.item(containing: pane) else { return false }
                return source.id != item
            case (.entry, .moveBefore), (.entry, .moveAfter):
                // A favourite or a tile, not a folder.
                guard let index = workspace.items.firstIndex(where: { $0.id == item }) else { return false }
                return canDropDragged(in: .today(at: action == .moveBefore ? index : index + 1))
            case (.document, _):
                return true
            case (.entry(let id), .split):
                // A favorite splits with a tab; a pinned tab does not.
                return !isPinned(id)
            case (nil, _):
                return false
        }
    }

    /// Drops what is dragged onto the tab row `item` with `action`.
    @discardableResult
    package func dropDragged(onto item: Workspace.ItemID, action: TabDropAction) -> Bool {
        if draggedSelection != nil, action != .split(.left), action != .split(.right) {
            return dropSelection(onTab: item, after: action == .moveAfter)
        }
        guard canDrop(onto: item, action: action) else { return false }
        bringDraggedHere()
        takeDocumentDrag()
        guard var drag = dragged else { return false }
        if case .entry(let entry) = drag, case .split = action {
            // A favorite dropped on a tab's half leaves the Favorites as a tab, then joins that tab as a split.
            guard let released = release(entry: entry) else { return false }
            drag = .item(released)
        } else if case .entry = drag {
            // A kept entry dropped among the tabs leaves the Favorites or the grid, as a tab at that place.
            guard let index = workspace.items.firstIndex(where: { $0.id == item }) else { return false }
            return dropDragged(in: .today(at: action == .moveBefore ? index : index + 1))
        }
        dragged = nil
        // Put in order among the tabs, a pane of a split moves its whole tab; on a row's half it still joins it.
        var moved = drag
        if case .pane(let pane) = drag, action == .moveBefore || action == .moveAfter,
            let source = workspace.item(containing: pane)
        {
            moved = .item(source.id)
        }
        change { $0.applyTabDrop(moved, onto: item, action: action) }
        return true
    }
}
