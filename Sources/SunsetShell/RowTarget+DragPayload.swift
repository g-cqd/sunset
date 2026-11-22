import SunsetPane

extension RowTarget {
    /// What dragging the row drags: its tab, or its kept entry.
    var dragPayload: PaneDragPayload {
        switch self {
            case .tab(let id): .item(id)
            case .node(let id): .entry(id)
        }
    }
}
