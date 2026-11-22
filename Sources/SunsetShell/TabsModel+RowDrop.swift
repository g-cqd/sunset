import SunsetPane

/// A drop on a sidebar row, whichever kind it is (`View.rowDragAndDrop`).
extension TabsModel {
    /// Shows the row: its tab, or its kept entry.
    func show(_ row: RowTarget) {
        switch row {
            case .tab(let id): select(item: id)
            case .node(let id): select(entry: id)
        }
    }

    /// Whether what is dragged can be dropped on the row with `action`.
    func canDrop(on row: RowTarget, action: TabDropAction) -> Bool {
        switch row {
            case .tab(let id): canDrop(onto: id, action: action)
            case .node(let id): canDrop(onEntry: id, action: action)
        }
    }

    /// Drops what is dragged on the row with `action`.
    func dropDragged(on row: RowTarget, action: TabDropAction) -> Bool {
        switch row {
            case .tab(let id): dropDragged(onto: id, action: action)
            case .node(let id): dropDragged(onEntry: id, action: action)
        }
    }
}
