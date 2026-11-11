import SunsetPane

/// Several rows selected together (R3 step d, owner's answers): Cmd-click adds or removes one, Shift-click takes the range from the last one clicked, a
/// plain click selects one and shows it. A selection may hold tabs, entries and folders; it is cleared by a plain click and after an action.
extension TabsModel {
    /// The rows of the sidebar in the order it draws them: the Favorites as shown (a collapsed folder hides what it holds), then the window's tabs.
    package var rowOrder: [RowTarget] {
        favorites.favorites.rows(selected: workspace.selectedEntry).map { .node($0.id) }
            + workspace.items.map { .tab($0.id) }
    }

    package func isMarked(_ row: RowTarget) -> Bool { marked.contains(row) }

    /// A click on a row, with the modifiers held: Cmd toggles it in the selection, Shift takes the range; a plain click clears the selection (the
    /// caller then shows the row). Returns whether the click was a selection click (nothing is to be shown).
    @discardableResult
    package func click(_ row: RowTarget, command: Bool, shift: Bool) -> Bool {
        let order = rowOrder
        if shift, let anchor = markAnchor ?? shownRow, let from = order.firstIndex(of: anchor),
            let to = order.firstIndex(of: row)
        {
            marked = Array(order[min(from, to) ... max(from, to)])
            return true
        }
        if command {
            if marked.isEmpty, let shown = shownRow, shown != row { marked = [shown] }
            if let index = marked.firstIndex(of: row) { marked.remove(at: index) } else { marked.append(row) }
            marked = order.filter(marked.contains)
            markAnchor = row
            return true
        }
        clearMarks()
        markAnchor = row
        return false
    }

    package func clearMarks() {
        marked = []
        markAnchor = nil
    }

    /// The row of what is shown: the kept entry, or the window's tab.
    var shownRow: RowTarget? { workspace.selectedEntry.map(RowTarget.node) ?? workspace.selectedID.map(RowTarget.tab) }

    /// What a drag of `row` carries: the whole selection when `row` is in it, else `row` alone.
    package func dragRows(for row: RowTarget) -> [RowTarget] { marked.contains(row) ? marked : [row] }

    // MARK: Acting on the selection

    /// The selection, or `row` alone when it is not in the selection (a menu opened on a row that is not selected acts on that row).
    package func rows(actingOn row: RowTarget) -> [RowTarget] { dragRows(for: row) }

    /// Puts the rows in a new folder at the end of the Favorites, in their order: tabs are kept there, entries and folders move there. Its name is edited.
    package func group(_ rows: [RowTarget]) {
        var made: Favorites.NodeID?
        favorites.edit { made = $0.addFolder(named: "New Folder") }
        guard let made else { return }
        move(rows, into: made, at: nil)
        renamingRow = .node(made)
        clearMarks()
    }

    /// Keeps the tabs among the rows, at the end of the Favorites, in order (entries and folders are kept already).
    package func addToFavorites(_ rows: [RowTarget]) {
        for case .tab(let id) in rows { keep(item: id, show: false) }
        clearMarks()
    }

    /// Takes the entries among the rows out of the Favorites, as tabs after the window's selected tab, in order (folders stay).
    package func removeFromFavorites(_ rows: [RowTarget]) {
        var index = workspace.selectedIndex.map { $0 + 1 } ?? workspace.count
        for case .node(let id) in rows where favorites.favorites.entry(id) != nil {
            release(entry: id, at: index)
            index += 1
        }
        clearMarks()
    }

    /// Deletes the entries and folders among the rows (a folder with what it holds); asks first, once, when something runs in any of them.
    package func delete(_ rows: [RowTarget]) {
        let nodes = rows.compactMap { if case .node(let id) = $0 { id } else { nil } }
        let open = nodes.flatMap { id -> [Workspace.Item] in
            guard let node = favorites.favorites.node(id) else { return [] }
            return Self.openItems(in: [node])
        }
        let busy = open.flatMap(\.panes).contains { favorites.contents[$0]?.closeWarning != nil }
        if let first = open.first { guard confirmed(.item(first.id), isBusy: busy) else { return } }
        for id in nodes { favorites.delete(id) }
        clearMarks()
        finishClosing()
    }

    /// Moves rows into `folder` (the top of the Favorites for nil) at `index` (the end for nil): tabs are kept there, nodes move there.
    func move(_ rows: [RowTarget], into folder: Favorites.NodeID?, at index: Int?) {
        var place = index
        for row in rows {
            switch row {
                case .tab(let id):
                    keep(item: id, in: folder, at: place, show: false)
                case .node(let id):
                    favorites.edit { $0.move([id], into: folder, at: place ?? Int.max) }
            }
            place = place.map { $0 + 1 }
        }
    }

    private static func openItems(in nodes: [Favorites.Node]) -> [Workspace.Item] {
        nodes.flatMap { node -> [Workspace.Item] in
            switch node {
                case .entry(let entry): entry.open.map { [$0] } ?? []
                case .folder(let folder): openItems(in: folder.children)
            }
        }
    }
}

/// Dragging a selection (R3 step d): a drag of a selected row carries every selected row, in order.
extension TabsModel {
    /// The selection being dragged, when the dragged row is one of several selected; nil for a drag of one row.
    var draggedSelection: [RowTarget]? {
        let row: RowTarget? =
            switch dragged {
                case .item(let id): .tab(id)
                case .entry(let id): .node(id)
                case .pane, nil: nil
            }
        guard let row, marked.count > 1, marked.contains(row) else { return nil }
        return marked
    }

    /// Puts the dragged selection next to the Favorites node `anchor`, each after the one before; true when there was a selection to drop.
    func dropSelection(nextTo anchor: Favorites.NodeID, after: Bool) -> Bool {
        guard let rows = draggedSelection, !rows.contains(.node(anchor)) else { return false }
        dragged = nil
        var target = anchor
        var behind = after
        for row in rows {
            guard let place = favorites.favorites.location(of: target) else { break }
            let index = place.index + (behind ? 1 : 0)
            switch row {
                case .tab(let id):
                    if let kept = keep(item: id, in: place.parent, at: index, show: false) { target = kept }
                case .node(let id):
                    let before =
                        favorites.favorites.location(of: id).map { $0.parent == place.parent && $0.index < place.index }
                        ?? false
                    favorites.edit { $0.move([id], into: place.parent, at: index - (before ? 1 : 0)) }
                    target = id
            }
            behind = true
        }
        clearMarks()
        return true
    }

    /// Puts the dragged selection into a folder (the top of the Favorites for nil), at its end; true when there was a selection to drop.
    func dropSelection(into folder: Favorites.NodeID?) -> Bool {
        guard let rows = draggedSelection, folder.map({ !rows.contains(.node($0)) }) ?? true else { return false }
        dragged = nil
        move(rows, into: folder, at: nil)
        clearMarks()
        return true
    }

    /// Puts the dragged selection among the tabs before or after the tab `target`: tabs move there, entries leave the Favorites there; folders stay.
    func dropSelection(onTab target: Workspace.ItemID, after: Bool) -> Bool {
        guard let rows = draggedSelection, !rows.contains(.tab(target)) else { return false }
        dragged = nil
        var anchor = target
        for row in rows {
            guard let at = workspace.items.firstIndex(where: { $0.id == anchor }) else { break }
            switch row {
                case .tab(let id):
                    guard let from = workspace.items.firstIndex(where: { $0.id == id }) else { continue }
                    let wanted = anchor == target && !after ? at : at + 1
                    change { $0.move(item: id, to: from < wanted ? wanted - 1 : wanted) }
                    anchor = id
                case .node(let id):
                    guard favorites.favorites.entry(id) != nil else { continue }
                    let item = favorites.favorites.entry(id)?.open?.id
                    release(entry: id, at: anchor == target && !after ? at : at + 1)
                    if let item {
                        anchor = item
                    } else if let index = workspace.selectedIndex {
                        anchor = workspace.items[index].id
                    }
            }
        }
        clearMarks()
        return true
    }
}
