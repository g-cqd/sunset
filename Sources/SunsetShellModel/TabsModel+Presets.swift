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

    /// The rows a layout takes: tabs, and favorites (which leave the Favorites for it); not pinned tabs, not folders (the
    /// owner, 2026-11-21: favorites could not be split).
    package func layoutRows(_ rows: [RowTarget]) -> [RowTarget] {
        rows.filter { row in
            switch row {
                case .tab: true
                case .node(let id): favorites.favorites.entry(id) != nil && !isPinned(id)
            }
        }
    }

    /// The layouts for as many panes as `rows` hold together: a favorite counts its home's panes.
    package func layoutPresets(for rows: [RowTarget]) -> [SplitPreset] {
        let taken = layoutRows(rows)
        guard taken.count > 1 else { return [] }
        let panes = taken.reduce(0) { count, row in
            switch row {
                case .tab(let id): count + (workspace.items.first { $0.id == id }?.panes.count ?? 0)
                case .node(let id): count + (favorites.favorites.entry(id)?.home.contents.count ?? 0)
            }
        }
        return SplitPreset.allCases.filter { $0.paneCount == panes }
    }

    /// Lays `rows` out together as `preset` says: each favorite among them leaves the Favorites as a tab first.
    package func apply(_ preset: SplitPreset, to rows: [RowTarget]) {
        let ids = layoutRows(rows)
            .compactMap { row -> Workspace.ItemID? in
                switch row {
                    case .tab(let id): id
                    case .node(let id): release(entry: id)
                }
            }
        apply(preset, to: ids)
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
