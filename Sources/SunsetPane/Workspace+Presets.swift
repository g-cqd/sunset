extension Workspace {
    /// The layouts that fit the tabs `ids` (n78, t287): those of as many panes as they hold together.
    /// - Parameter ids: Tabs of this window.
    /// - Returns: The presets, in their order; none when a tab is not here.
    public func presets(for ids: [ItemID]) -> [SplitPreset] {
        let found = ids.compactMap { id in items.first { $0.id == id } }
        guard found.count == ids.count, !found.isEmpty else { return [] }
        let count = found.reduce(0) { $0 + $1.panes.count }
        return SplitPreset.allCases.filter { $0.paneCount == count }
    }

    /// Lays the tabs `ids` out together as `preset` says (the owner, 2026-11-17: several tabs selected, or one split tab):
    /// their panes, in the sidebar's order, become one tab where the first of them is, shown; the others go.
    /// - Parameters:
    ///   - preset: The shape; it must take as many panes as the tabs hold.
    ///   - ids: Tabs of this window.
    /// - Returns: False, and nothing changed, when the preset does not fit them.
    @discardableResult
    public mutating func apply(_ preset: SplitPreset, to ids: [ItemID]) -> Bool {
        guard presets(for: ids).contains(preset) else { return false }
        let ordered = items.filter { ids.contains($0.id) }
        let first = ordered[0]
        let panes = ordered.flatMap(\.panes)
        items.removeAll { ids.contains($0.id) && $0.id != first.id }
        guard let index = items.firstIndex(where: { $0.id == first.id }) else { return false }
        items[index].layout = preset.layout(of: panes)
        show(first.id)
        return true
    }
}
