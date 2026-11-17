package import SunsetPane

/// A window and the Favorites (R3, R4): it shows a kept entry instead of one of its tabs, keeps a tab, takes one back out.
extension TabsModel {
    /// The kept entry this window shows, when it shows one.
    package var shownEntry: Favorites.Entry? { workspace.selectedEntry.flatMap { keeper(of: $0).favorites.entry($0) } }
    /// Whether this window draws what it shows; false while the tab or the kept entry it shows is live in another window (it
    /// shows the last picture then).
    package var showsLive: Bool {
        if let entry = selectedEntry { return keeper(of: entry).isLive(entry, in: self) }
        return selectedID.map { space.isLive($0, in: self) } ?? true
    }

    /// Brings what this window shows here from the window it was live in (a click on its picture, or on its tab).
    package func takeShown() {
        if let id = selectedEntry {
            select(entry: id)
        } else if let id = selectedID {
            space.claim(id, by: self, force: true)
            syncStates()
        }
    }

    /// The window came to the front: it draws what it shows, which the window that drew it shows as a picture (the owner,
    /// 2026-11-17, roadmap 0035 J; supersedes ADR-0045's "bringing a window to the front takes nothing").
    package func cameToFront() {
        guard !showsLive else { return }
        takeShown()
    }

    /// What the pane area shows: the kept entry's live tab, or the window's selected tab.
    package var shownItem: Workspace.Item? {
        workspace.selectedEntry == nil ? workspace.selectedItem : shownEntry?.open
    }
    /// The pane that has the keyboard.
    package var shownPane: PaneID? { shownItem?.focused }

    /// The content of a pane of this window or of a kept entry.
    package func content(_ pane: PaneID) -> (any PaneContent)? {
        contents[pane] ?? favorites.contents[pane] ?? pinned?.contents[pane]
    }

    /// Whether the row of the tab `item` is the selected one (no kept entry is shown instead).
    package func isSelected(_ item: Workspace.ItemID) -> Bool {
        workspace.selectedEntry == nil && workspace.selectedID == item
    }

    /// Keeps the tab `item` in the Favorites (in `parent`, the top for nil, at `index`, or at the end): its content keeps running there, and this window
    /// shows it as a kept entry.
    @discardableResult
    package func keep(
        item: Workspace.ItemID,
        in parent: Favorites.NodeID? = nil,
        at index: Int? = nil,
        show: Bool = true
    )
        -> Favorites.NodeID?
    {
        guard let taken = workspace.take(item: item) else { return nil }
        var moved: [PaneID: any PaneContent] = [:]
        for pane in taken.panes { moved[pane] = contents.removeValue(forKey: pane) }
        guard let id = favorites.keep(taken, contents: moved, in: parent, at: index) else { return nil }
        for (pane, content) in moved { content.onExit = { [weak self] in self?.favorites.close(pane: pane) } }
        if show {
            showEntry(id)
        } else {
            syncStates()
            onChange()
        }
        return id
    }

    /// Shows a kept entry in this window, opening it first when it is not open (its panes start from where it was kept).
    package func select(entry id: Favorites.NodeID) {
        // An entry of a scope that is off is not opened (it is not listed either).
        guard keeper(of: id).favorites.entry(id).map(scopes.allows) != false,
            keeper(of: id).open(id, make: makeContent) != nil
        else { return }
        showEntry(id)
    }

    /// Takes a kept entry out of the Favorites as a tab of this window, at `index` (after its selected tab when nil), selected.
    @discardableResult
    package func release(entry id: Favorites.NodeID, at index: Int? = nil) -> Workspace.ItemID? {
        guard let released = keeper(of: id).release(id) else { return nil }
        let index = index ?? workspace.selectedIndex.map { $0 + 1 } ?? workspace.count
        workspace.insert(released.item, at: index)
        for pane in released.item.panes {
            let content = released.live[pane] ?? makeContent(released.home[pane] ?? .terminal(directory: nil))
            register(content, as: pane)
        }
        syncStates()
        onChange()
        return released.item.id
    }

    /// Unloads the kept entry: what runs in it stops (asking first when something would be lost), it stays in the Favorites.
    package func unload(entry id: Favorites.NodeID) {
        let favorites = keeper(of: id)
        guard let open = favorites.favorites.entry(id)?.open else { return }
        let busy = open.panes.contains { favorites.contents[$0]?.closeWarning != nil }
        guard confirmed(.item(open.id), isBusy: busy) else { return }
        losingNothing(closing: open.panes) { [self] in
            favorites.unload(id)
            finishClosing()
        }
    }

    /// Removes a kept entry for good (what runs in it stops, asking first when something would be lost).
    package func delete(entry id: Favorites.NodeID) {
        let favorites = keeper(of: id)
        let open = favorites.favorites.entry(id)?.open
        let busy = open?.panes.contains { favorites.contents[$0]?.closeWarning != nil } ?? false
        if let open { guard confirmed(.item(open.id), isBusy: busy) else { return } }
        losingNothing(closing: open?.panes ?? []) { [self] in
            favorites.delete(id)
            finishClosing()
        }
    }

    /// This window shows its own selected tab again (the entry it showed stopped, went, or is shown in another window now).
    func leaveEntry() {
        guard let entry = workspace.selectedEntry else { return }
        workspace.select(entry: nil)
        left(entry)
        syncStates()
        if workspace.isEmpty, favorites.isEmpty { emptied() }
    }

    /// This window stopped showing `id` (another tab or entry is shown): when it was live here, its panes are told they are hidden, and it goes live in
    /// another window that shows it.
    func left(_ id: Favorites.NodeID) {
        let favorites = keeper(of: id)
        guard favorites.isLive(id, in: self) else { return }
        for pane in favorites.favorites.entry(id)?.open?.panes ?? [] {
            favorites.contents[pane]?.setState(focused: false, visible: false)
        }
        favorites.unclaim(id, by: self)
    }

    func showEntry(_ id: Favorites.NodeID) {
        let previous = workspace.selectedEntry
        let favorites = keeper(of: id)
        favorites.claim(id, by: self)
        for pane in favorites.favorites.entry(id)?.open?.panes ?? [] {
            favorites.contents[pane]?.onFocusRequest = { [weak self] in
                guard let self, shownItem?.panes.contains(pane) == true else { return }
                focus(pane)
            }
        }
        workspace.select(entry: id)
        if let previous, previous != id { left(previous) }
        syncStates()
        onChange()
    }

    /// Where Cmd-1 to 9 and Next and Previous Tab go, in order: the kept entries that are open, in the order of the Favorites, then the window's tabs.
    /// What is not open is not counted: stepping never starts anything (R3).
    enum Stop: Equatable {
        case entry(Favorites.NodeID)
        case tab(Workspace.ItemID)
    }

    var stops: [Stop] {
        favorites.favorites.entries.filter(\.isOpen).map { .entry($0.id) } + workspace.items.map { .tab($0.id) }
    }

    func step(by offset: Int) {
        let stops = self.stops
        let current: Stop? = workspace.selectedEntry.map { .entry($0) } ?? workspace.selectedID.map { .tab($0) }
        guard !stops.isEmpty, let current, let index = stops.firstIndex(of: current) else { return }
        go(to: stops[(index + offset + stops.count) % stops.count])
    }

    func go(to stop: Stop) {
        switch stop {
            case .entry(let id): select(entry: id)
            case .tab(let id): select(item: id)
        }
    }
}

/// Dragging across the line between the Favorites and the tabs (R3): a tab dropped above it is kept, an entry dropped below it leaves the Favorites.
extension TabsModel {
    /// Whether what is dragged can be dropped on the row of the kept entry `target` (a tab is kept beside it, an entry moves beside it).
    package func canDrop(onEntry target: Favorites.NodeID) -> Bool {
        if case .entry(target)? = dragged { return false }
        guard let place = favorites.favorites.location(of: target) else { return false }
        return canDropDragged(in: .favorites(in: place.parent, at: place.index))
    }

    /// Drops what is dragged before or after the row of the kept entry `target`, in the folder that holds it.
    @discardableResult
    package func dropDragged(onEntry target: Favorites.NodeID, after: Bool) -> Bool {
        if draggedSelection != nil { return dropSelection(nextTo: target, after: after) }
        guard canDrop(onEntry: target), let place = favorites.favorites.location(of: target) else { return false }
        // Whatever it is (a tab, a split, a favourite, a tile, a document), it goes there (roadmap 0035 A).
        return dropDragged(in: .favorites(in: place.parent, at: place.index + (after ? 1 : 0)))
    }

    /// Whether what is dragged can be dropped on the line under the Favorites: a tab or a document, kept at their end.
    package var canDropOnFavoritesLine: Bool {
        if draggedSelection != nil { return true }
        return canDropDragged(in: .favorites(in: nil, at: nil))
    }

    /// Drops a dragged tab on the line under the Favorites: it is kept at their end.
    @discardableResult
    package func dropDraggedOnFavoritesLine() -> Bool {
        if draggedSelection != nil { return dropSelection(into: nil) }
        return dropDragged(in: .favorites(in: nil, at: nil))
    }
}
