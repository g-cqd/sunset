package import SunsetPane

/// A window and the Pinned grid (roadmap 0021, P-b; ADR-0050): the app's grid of kept entries, the same in every Space.
/// An entry of the grid is kept as an entry of the Favorites is (shown instead of a tab, unloaded by Cmd-W, drawn in one
/// window); it is only kept elsewhere, so what acts on an entry asks which of the two keeps it (`keeper(of:)`).
extension TabsModel {
    /// The most the grid holds: "up to 3x4 items or 4x3" (the owner).
    package static let pinnedLimit = 12

    /// The Favorites or the Pinned grid, whichever keeps the entry `id`; the Favorites when neither does.
    func keeper(of id: Favorites.NodeID) -> FavoritesModel {
        if let pinned, pinned.favorites.entry(id) != nil { pinned } else { favorites }
    }

    /// The Favorites or the Pinned grid, whichever keeps the pane, when one does.
    func keeper(ofPane pane: PaneID) -> FavoritesModel? {
        if favorites.favorites.entry(containing: pane) != nil { return favorites }
        if let pinned, pinned.favorites.entry(containing: pane) != nil { return pinned }
        return nil
    }

    /// Shows the Pinned grid of the profile of this window's Space (a window among the app's Spaces): another Space,
    /// or another profile for the Space, is another grid. An entry of the grid it leaves is no longer shown here.
    func followProfile() {
        guard let spaces else { return }
        let grid = spaces.profiles.profile(of: space.space).pinned
        guard grid !== pinned else { return }
        if let shown = selectedEntry, pinned?.favorites.entry(shown) != nil {
            left(shown)
            selectedEntry = nil
        }
        pinned = grid
        syncStates()
    }

    /// Stops showing the kept entry this window shows, without closing it: its Space is given another profile.
    func leaveKeptEntry() {
        guard let shown = selectedEntry else { return }
        left(shown)
        selectedEntry = nil
    }

    /// The entries of the grid this window shows: those of a scope that is off are hidden (roadmap 0033).
    package var pinnedEntries: [Favorites.Entry] { (pinned?.favorites.entries ?? []).filter(scopes.allows) }
    package func isPinned(_ id: Favorites.NodeID) -> Bool { pinned?.favorites.entry(id) != nil }
    /// There is a grid, and room in it.
    package var canPin: Bool { pinned.map { $0.favorites.entries.count < Self.pinnedLimit } ?? false }

    /// Pins the tab `item`: it leaves the Tabs for the grid, where its content keeps running, and this window shows it
    /// there. Nil when there is no grid or no room.
    @discardableResult
    package func pin(item: Workspace.ItemID, show: Bool = true, at index: Int? = nil) -> Favorites.NodeID? {
        guard canPin, let pinned, let taken = workspace.take(item: item) else { return nil }
        var moved: [PaneID: any PaneContent] = [:]
        for pane in taken.panes { moved[pane] = contents.removeValue(forKey: pane) }
        guard let id = pinned.keep(taken, contents: moved, in: nil, at: index) else { return nil }
        for (pane, content) in moved { content.onExit = { [weak pinned] in pinned?.close(pane: pane) } }
        if show {
            showEntry(id)
        } else {
            syncStates()
            onChange()
        }
        return id
    }

    /// Whether the row could be pinned: a tab, or an entry of the Favorites (a folder is not pinned), with room in the grid.
    package func canPin(_ row: RowTarget) -> Bool {
        guard canPin else { return false }
        switch row {
            case .tab(let id): return workspace.items.contains { $0.id == id }
            case .node(let id): return favorites.favorites.entry(id) != nil
        }
    }

    /// Pins an entry of the Favorites: the same entry, as it is, goes to the grid (open, it runs on, and a window that
    /// shows it goes on showing it). False for a folder, for one already pinned, and with no room.
    @discardableResult
    package func pin(entry id: Favorites.NodeID, at index: Int? = nil) -> Bool {
        guard canPin, let pinned, favorites.give(id, to: pinned, at: index) else { return false }
        marked.removeAll { $0 == .node(id) }
        syncStates()
        onChange()
        return true
    }

    /// Makes a pinned entry a favourite: the same entry, as it is, in the Favorites of the Space shown (at the end, unless a
    /// folder and a place are given).
    @discardableResult
    package func favorite(pinned id: Favorites.NodeID, in parent: Favorites.NodeID? = nil, at index: Int? = nil) -> Bool
    {
        guard let pinned, pinned.give(id, to: favorites, in: parent, at: index) else { return false }
        syncStates()
        onChange()
        return true
    }

    /// Pins the tabs and the favourites among `rows`, in order, while there is room; says how many.
    @discardableResult
    package func pin(_ rows: [RowTarget]) -> Int {
        var count = 0
        for row in rows {
            switch row {
                case .tab(let id): if pin(item: id, show: false) != nil { count += 1 }
                case .node(let id): if pin(entry: id) { count += 1 }
            }
        }
        clearMarks()
        return count
    }

    /// What is dragged, as rows: the rows marked when the dragged one is among them, else the dragged one alone.
    private var draggedRows: [RowTarget] {
        if let several = draggedSelection { return several }
        switch dragged {
            case .item(let id): return [.tab(id)]
            case .entry(let id): return [.node(id)]
            case .pane, .document, nil: return []
        }
    }

    /// Pins what is dragged (a tab's row, a favourite's, or the rows marked): dropped on the grid.
    package func pinDragged() -> Bool {
        guard draggedSelection != nil else { return dropDragged(in: .pinned(at: nil)) }
        let rows = draggedRows
        dragged = nil
        return pin(rows) > 0
    }

    /// Whether what is dragged could be pinned: a tab, a split, a favourite, with room for one more; a tile, moved in the grid.
    package var canPinDragged: Bool {
        draggedSelection == nil ? canDropDragged(in: .pinned(at: nil)) : draggedRows.contains { canPin($0) }
    }

    /// Starts a kept entry again from where it was pinned or kept: what it runs is stopped (asking first when something
    /// would be lost, as unloading does), and it opens anew (a page at its address, a terminal in its folder). The owner,
    /// 2026-11-17: in the menu, not on a second click.
    package func reset(entry id: Favorites.NodeID) {
        let keeper = keeper(of: id)
        guard let entry = keeper.favorites.entry(id) else { return }
        guard let open = entry.open else { return select(entry: id) }
        let busy = open.panes.contains { keeper.contents[$0]?.closeWarning != nil }
        guard confirmed(.item(open.id), isBusy: busy) else { return }
        losingNothing(closing: open.panes) { [self] in
            if workspace.selectedEntry == id { left(id) }
            keeper.unload(id)
            select(entry: id)
        }
    }
}
