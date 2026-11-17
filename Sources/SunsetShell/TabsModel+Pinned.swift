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

    package var pinnedEntries: [Favorites.Entry] { pinned?.favorites.entries ?? [] }
    package func isPinned(_ id: Favorites.NodeID) -> Bool { pinned?.favorites.entry(id) != nil }
    /// There is a grid, and room in it.
    package var canPin: Bool { pinned.map { $0.favorites.entries.count < Self.pinnedLimit } ?? false }

    /// Pins the tab `item`: it leaves the Tabs for the grid, where its content keeps running, and this window shows it
    /// there. Nil when there is no grid or no room.
    @discardableResult
    package func pin(item: Workspace.ItemID, show: Bool = true) -> Favorites.NodeID? {
        guard canPin, let pinned, let taken = workspace.take(item: item) else { return nil }
        var moved: [PaneID: any PaneContent] = [:]
        for pane in taken.panes { moved[pane] = contents.removeValue(forKey: pane) }
        guard let id = pinned.keep(taken, contents: moved, in: nil, at: nil) else { return nil }
        for (pane, content) in moved { content.onExit = { [weak pinned] in pinned?.close(pane: pane) } }
        if show {
            showEntry(id)
        } else {
            syncStates()
            onChange()
        }
        return id
    }

    /// Pins the tabs that are dragged (a row, or the rows marked): dropped on the grid.
    package func pinDragged() -> Bool {
        let rows = draggedSelection ?? []
        dragged = nil
        var pinnedAny = false
        for case .tab(let id) in rows where pin(item: id, show: false) != nil { pinnedAny = true }
        return pinnedAny
    }

    /// Whether what is dragged could be pinned: a tab, or tabs, with room for one more.
    package var canPinDragged: Bool {
        canPin && (draggedSelection ?? []).contains { if case .tab = $0 { true } else { false } }
    }

    /// Starts a pinned entry again from where it was pinned: what it runs is stopped, and it opens anew (a page at its
    /// pinned address, a terminal in its folder). The owner, 2026-11-17: in the tile's menu, not on a second click.
    package func reset(entry id: Favorites.NodeID) {
        let keeper = keeper(of: id)
        guard keeper.favorites.entry(id) != nil else { return }
        if workspace.selectedEntry == id { left(id) }
        keeper.unload(id)
        select(entry: id)
    }
}
