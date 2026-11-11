package import SunsetPane

/// A window and the Favorites (R3, R4): it shows a kept entry instead of one of its tabs, keeps a tab, takes one back out.
extension TabsModel {
    /// The kept entry this window shows, when it shows one.
    package var shownEntry: Favorites.Entry? { workspace.selectedEntry.flatMap { favorites.favorites.entry($0) } }
    /// Whether this window draws what it shows; false while the kept entry it shows is live in another window (it shows the last picture then).
    package var showsLive: Bool { workspace.selectedEntry.map { favorites.isLive($0, in: self) } ?? true }

    /// Brings the entry this window shows here from the window it was live in (a click on its picture).
    package func takeShownEntry() { if let id = workspace.selectedEntry { select(entry: id) } }

    /// What the pane area shows: the kept entry's live tab, or the window's selected tab.
    package var shownItem: Workspace.Item? {
        workspace.selectedEntry == nil ? workspace.selectedItem : shownEntry?.open
    }
    /// The pane that has the keyboard.
    package var shownPane: PaneID? { shownItem?.focused }

    /// The content of a pane of this window or of a kept entry.
    package func content(_ pane: PaneID) -> (any PaneContent)? { contents[pane] ?? favorites.contents[pane] }

    /// Whether the row of the tab `item` is the selected one (no kept entry is shown instead).
    package func isSelected(_ item: Workspace.ItemID) -> Bool {
        workspace.selectedEntry == nil && workspace.selectedID == item
    }

    /// Keeps the tab `item` in the Favorites: its content keeps running there, and this window shows it as a kept entry.
    package func keep(item: Workspace.ItemID) {
        guard let taken = workspace.take(item: item) else { return }
        var moved: [PaneID: any PaneContent] = [:]
        for pane in taken.panes { moved[pane] = contents.removeValue(forKey: pane) }
        guard let id = favorites.keep(taken, contents: moved) else { return }
        for (pane, content) in moved { content.onExit = { [weak self] in self?.favorites.close(pane: pane) } }
        showEntry(id)
    }

    /// Shows a kept entry in this window, opening it first when it is not open (its panes start from where it was kept).
    package func select(entry id: Favorites.NodeID) {
        guard favorites.open(id, make: makeContent) != nil else { return }
        showEntry(id)
    }

    /// Takes a kept entry out of the Favorites as a tab of this window, after its selected tab, selected.
    package func release(entry id: Favorites.NodeID) {
        guard let released = favorites.release(id) else { return }
        let index = workspace.selectedIndex.map { $0 + 1 } ?? workspace.count
        workspace.insert(released.item, at: index)
        for pane in released.item.panes {
            let content = released.live[pane] ?? makeContent(released.home[pane] ?? .terminal(directory: nil))
            register(content, as: pane)
        }
        syncStates()
        onChange()
    }

    /// Unloads the kept entry: what runs in it stops (asking first when something would be lost), it stays in the Favorites.
    package func unload(entry id: Favorites.NodeID) {
        guard let open = favorites.favorites.entry(id)?.open else { return }
        let busy = open.panes.contains { favorites.contents[$0]?.closeWarning != nil }
        guard confirmed(.item(open.id), isBusy: busy) else { return }
        favorites.unload(id)
        finishClosing()
    }

    /// Removes a kept entry for good (what runs in it stops, asking first when something would be lost).
    package func delete(entry id: Favorites.NodeID) {
        let open = favorites.favorites.entry(id)?.open
        let busy = open?.panes.contains { favorites.contents[$0]?.closeWarning != nil } ?? false
        if let open { guard confirmed(.item(open.id), isBusy: busy) else { return } }
        favorites.delete(id)
        finishClosing()
    }

    /// This window shows its own selected tab again (the entry it showed stopped, went, or is shown in another window now).
    func leaveEntry() {
        guard let entry = workspace.selectedEntry else { return }
        workspace.select(entry: nil)
        left(entry)
        syncStates()
        if workspace.isEmpty, favorites.isEmpty { onEmpty() }
    }

    /// This window stopped showing `id` (another tab or entry is shown): when it was live here, its panes are told they are hidden, and it goes live in
    /// another window that shows it.
    func left(_ id: Favorites.NodeID) {
        guard favorites.isLive(id, in: self) else { return }
        for pane in favorites.favorites.entry(id)?.open?.panes ?? [] {
            favorites.contents[pane]?.setState(focused: false, visible: false)
        }
        favorites.unclaim(id, by: self)
    }

    func showEntry(_ id: Favorites.NodeID) {
        let previous = workspace.selectedEntry
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
