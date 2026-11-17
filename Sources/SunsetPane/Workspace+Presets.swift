extension Workspace {
    /// Lays the tab `id` out as `preset` says (n78, t287): with too few panes, the panes of the tabs after it join, in their
    /// order; with too many, the extra ones become tabs right after it. The tab stays selected and keeps its focus when it can.
    /// - Parameters:
    ///   - preset: The shape.
    ///   - id: The tab.
    /// - Returns: False, and nothing changed, when the tab and those after it hold too few panes.
    @discardableResult
    public mutating func apply(_ preset: SplitPreset, to id: ItemID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        let need = preset.paneCount
        let available = items[index...].reduce(0) { $0 + $1.panes.count }
        guard available >= need else { return false }
        var panes = items[index].panes
        while panes.count < need, index + 1 < items.count {
            var next = items[index + 1]
            let pane = next.panes[0]
            panes.append(pane)
            if next.remove(pane) { items[index + 1] = next } else { items.remove(at: index + 1) }
        }
        let extra = panes.dropFirst(need)
        for (offset, pane) in extra.enumerated() {
            items.insert(Item(layout: .pane(pane), focused: pane), at: index + 1 + offset)
        }
        let kept = Array(panes.prefix(need))
        items[index].layout = preset.layout(of: kept)
        if !kept.contains(items[index].focused) { items[index].focused = kept[0] }
        return true
    }
}
