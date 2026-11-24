package import SunsetPane

/// A window as a view of its Space: the Space's tabs with this window's selection.
extension TabsModel {
    /// The Space's tabs, with this window's selection. Changing it changes the Space's tabs for every window that shows
    /// them, and this window's selection only.
    package internal(set) var workspace: Workspace {
        get {
            space.tabs.selecting(selectedID, entry: selectedEntry)
        }
        set {
            let was = shownTab
            selectedID = newValue.selectedID
            selectedEntry = newValue.selectedEntry
            space.set(newValue, by: self)
            let now = shownTab
            guard was != now else { return }
            // Shown by something other than a click (a new tab, the neighbour of one that closed): taken only from no one.
            if let now { space.claim(now, by: self, force: false) }
            if let was { space.unclaim(was, by: self) }
            // A tab that waited is made as it is shown; a new tab's content is made by whoever opened it, not here.
            if now != nil { revive(onlyKept: true) }
        }
    }

    /// The content of every pane of the Space's tabs.
    package internal(set) var contents: [PaneID: any PaneContent] {
        get {
            space.contents
        }
        set {
            space.contents = newValue
        }
    }

    /// The tab this window shows: its selected one, unless it shows a kept entry instead.
    package var shownTab: Workspace.ItemID? {
        selectedEntry == nil ? selectedID : nil
    }

    /// Another window changed the Space's tabs, which were `old`: a selection that went moves to the neighbour (without
    /// taking it from a window that draws it), and the window goes with the last tab as when it closes it itself.
    package func tabsChanged(from old: [Workspace.Item]) {
        let items = space.tabs.items
        let present = Set(items.map(\.id))
        if let selected = selectedID, !present.contains(selected) {
            let index = old.firstIndex { $0.id == selected } ?? 0
            selectedID = items.isEmpty ? nil : items[min(index, items.count - 1)].id
            if let now = shownTab { space.claim(now, by: self, force: false) }
        }
        marked.removeAll { if case .tab(let id) = $0 { !present.contains(id) } else { false } }
        if let hovered = hoveredItem, previewItem(hovered) == nil { hoveredItem = nil }
        if items.isEmpty, selectedEntry == nil, favorites.isEmpty, pinned?.isEmpty ?? true { emptied() }
    }

    /// Gives their content to the panes of the tab this window shows that have none, from what was kept for each; once this
    /// window was told how content is made (before that it could only make placeholders). The other tabs wait, listed and
    /// not loaded, each with what it starts from, until one is shown (n146): a launch started every shell of the last session.
    package func revive(onlyKept: Bool = false) {
        guard canMake, let shown = shownTab else { return }
        guard let item = space.tabs.items.first(where: { $0.id == shown }) else { return }
        for pane in item.panes where space.contents[pane] == nil && (!onlyKept || space.pending[pane] != nil) {
            register(makeContent(space.takePending(pane) ?? .terminal(directory: nil)), as: pane)
        }
    }

    /// Whether the menu offers Unload for the tab `id`: loaded, not shown by any window, and made only of documents (Markdown,
    /// rendered Markdown, source), terminals with no command running (unloaded, a terminal starts a new shell where it was)
    /// and pages not unloaded yet (a page keeps its address and its history).
    package func canUnload(item id: Workspace.ItemID) -> Bool {
        guard let item = space.tabs.items.first(where: { $0.id == id }),
            !space.currentViewers.contains(where: { $0 !== self && $0.shownTab == id }),
            shownTab != id || tabToShow(instead: id) != nil
        else { return false }
        let made = item.panes.compactMap { space.contents[$0] }
        let kinds: Set = [PaneDescriptor.documentKind, PaneDescriptor.terminalKind]
        return !made.isEmpty
            && made.allSatisfy {
                $0.unloadsInPlace ? !$0.isUnloaded : kinds.contains($0.descriptor.kind) && !$0.runsCommand
            }
    }

    /// Unloads the tab `id` by hand, after asking its pages whether they hold text typed and not sent.
    /// - Returns: what the menu says: done, or why not.
    package func unloadChecked(item id: Workspace.ItemID) async -> ActionFeedback {
        guard canUnload(item: id), let item = space.tabs.items.first(where: { $0.id == id }) else {
            return .blocked("It is shown, or something runs in it")
        }
        for pane in item.panes {
            if let content = space.contents[pane], content.unloadsInPlace, await content.holdsUnsentText() {
                return .blocked("Something typed in it is not sent")
            }
        }
        return unload(item: id) ? .done("Unloaded") : .blocked("It plays, captures or asks something")
    }

    /// The tab this window shows when `id`, which it shows, is unloaded: the one it showed before, else the next, else the
    /// previous; nil when there is none.
    private func tabToShow(instead id: Workspace.ItemID) -> Workspace.ItemID? {
        if let back = previouslyShown(before: id) { return back }
        let items = space.tabs.items
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        return items.indices.contains(index + 1) ? items[index + 1].id : (index > 0 ? items[index - 1].id : nil)
    }

    /// Unloads the tab `id` by hand (see `SpaceModel.unload`). The tab this window shows goes too: the window shows another
    /// first, as when it is closed; the tab stays in the list.
    @discardableResult
    package func unload(item id: Workspace.ItemID) -> Bool {
        if shownTab == id {
            guard let away = tabToShow(instead: id) else { return false }
            select(item: away)
            syncStates()
        }
        let done = space.unload(item: id)
        if done { onChange() }
        return done
    }

    /// The panes this window sets up (its font, what they ask of a window): those of the tabs it draws, and of the tabs no
    /// window draws. What another window draws is that window's.
    package var drawnPanes: [PaneID] {
        space.tabs.items.filter { space.isLive($0.id, in: self) || space.isFree($0.id) }.flatMap(\.panes)
    }

    /// This window shows `other` from now on. The tabs it had in a Space no other window shows go with it, after the
    /// Space's, still running, and it keeps its selection; a window that had none has nothing selected.
    package func join(_ other: SpaceModel) {
        guard other !== space else { return }
        let selected = selectedID
        let moved = space.give(to: self)
        if other.favorites !== space.favorites { selectedEntry = nil }
        selectedID = nil
        space = other
        other.register(self)
        other.favorites.register(self)
        var tabs = workspace
        for item in moved.items { tabs.insert(item, at: tabs.count) }
        workspace = tabs.selecting(selected, entry: selectedEntry)
        for (pane, content) in moved.contents { register(content, as: pane) }
        revive()
        syncStates()
    }

    /// Nothing is left to show: no tab, and nothing in the Favorites. A window among the app's Spaces stays, on its empty
    /// Space, unless it is told to close with its last tab; any other window is its tab, and closes.
    package func emptied() {
        guard spaces != nil, !closesWithLastTab else { return onEmpty() }
        syncStates()
    }

    /// Tells every content whether it is shown and whether it has the keyboard: the Space's tabs', each by the window it is
    /// live in, and the panes of the kept entry this window shows.
    package func syncStates() {
        space.syncStates()
        guard workspace.selectedEntry != nil, showsLive else { return }
        let focused = shownPane
        for pane in shownEntry?.open?.panes ?? [] {
            content(pane)?.setState(focused: pane == focused, visible: true)
        }
    }

    // MARK: Session

    /// This window as the session keeps it: its Space, and what it had selected of what the session keeps.
    package func savedView() -> SavedView {
        let selected = space.tabs.items.first { $0.id == selectedID }.flatMap { space.keeps($0) ? $0.id : nil }
        let entry = selectedEntry.flatMap { keeper(of: $0).favorites.entry($0)?.isOpen == true ? $0 : nil }
        return SavedView(space: space.space.id, selected: entry == nil ? selected : nil, entry: entry)
    }

    /// Shows what a saved view had selected: the tab (drawn here unless another window already draws it), or the entry.
    package func show(_ view: SavedView) {
        if let selected = view.selected, space.tabs.items.contains(where: { $0.id == selected }) {
            workspace = workspace.selecting(selected, entry: nil)
            syncStates()
        }
        if let entry = view.entry { select(entry: entry) }
    }
}
