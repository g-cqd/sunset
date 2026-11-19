package import SunsetPane

/// Laying tabs out from their menu (n78, t287; the owner, 2026-11-17): offered for several tabs selected, or for one split
/// tab, never for one plain tab.
extension TabsModel {
    /// The tabs a layout from the menu of `row` acts on: the selected tabs with it when there are several, or the row's own
    /// tab when it is a split; none else.
    /// - Parameter row: The row right-clicked.
    /// - Returns: Tabs of this window, or none.
    package func layoutTabs(for row: RowTarget) -> [Workspace.ItemID] {
        let ids = rows(actingOn: row)
            .compactMap { target -> Workspace.ItemID? in
                if case .tab(let id) = target { id } else { nil }
            }
        if ids.count > 1 { return ids }
        guard case .tab(let id) = row, workspace.items.first(where: { $0.id == id })?.isSplit == true else { return [] }
        return [id]
    }

    /// Lays the tabs `ids` out together as `preset` says, and shows them.
    /// - Parameters:
    ///   - preset: The shape.
    ///   - ids: The tabs.
    package func apply(_ preset: SplitPreset, to ids: [Workspace.ItemID]) {
        var tabs = workspace
        guard tabs.apply(preset, to: ids) else { return }
        workspace = tabs
        clearMarks()
        syncStates()
        onChange()
    }
}
