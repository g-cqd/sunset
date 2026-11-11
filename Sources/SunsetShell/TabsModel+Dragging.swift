package import Foundation
package import SunsetPane

extension TabsModel {
    // MARK: Dragging

    /// What a drag of a tab or a pane carries (as text). Called when the drag starts, not when the row is drawn: it remembers what is being dragged, so that
    /// the drop areas can tell at once what would happen.
    package func itemProvider(for payload: PaneDragPayload) -> NSItemProvider {
        dragged = payload
        return NSItemProvider(object: payload.text as NSString)
    }

    /// Whether what is dragged could be dropped on a pane: a pane not on itself; a tab on another tab's pane, or on its own when there is another tab to ask for
    /// (`choice`).
    package func canDrop(onto pane: PaneID) -> Bool {
        switch dragged {
            case .item(let id): workspace.item(containing: pane)?.id != id || workspace.count > 1
            case .pane(let id): id != pane
            case nil: false
        }
    }

    /// Drops what is dragged on `edge` of a pane (the tab joins that pane's tab, or the pane moves beside it).
    @discardableResult
    package func dropDragged(onto pane: PaneID, edge: PaneEdge) -> Bool {
        guard canDrop(onto: pane), let drag = dragged else { return false }
        dragged = nil
        switch drag {
            case .item(let id) where workspace.item(containing: pane)?.id == id:
                bar = CommandBar(purpose: .splitWith(SplitChoice(pane: pane, edge: edge)))
            case .item(let id): drop(item: id, onto: pane, edge: edge)
            case .pane(let id): movePane(id, beside: pane, edge: edge)
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
        switch (dragged, action) {
            case (.item(let id), _):
                return id != item
            case (.pane(let pane), .split):
                return workspace.item(containing: pane)?.focused != pane || workspace.item(containing: pane)?.id != item
            case (.pane(let pane), .moveBefore), (.pane(let pane), .moveAfter):
                guard let source = workspace.item(containing: pane) else { return false }
                return source.isSplit || source.id != item
            case (nil, _):
                return false
        }
    }

    /// Drops what is dragged onto the tab row `item` with `action`.
    @discardableResult
    package func dropDragged(onto item: Workspace.ItemID, action: TabDropAction) -> Bool {
        guard canDrop(onto: item, action: action), let drag = dragged else { return false }
        dragged = nil
        change { $0.applyTabDrop(drag, onto: item, action: action) }
        return true
    }
}
