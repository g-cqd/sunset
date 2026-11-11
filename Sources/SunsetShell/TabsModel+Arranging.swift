package import SunsetPane

extension TabsModel {
    // MARK: Selecting and arranging

    package func select(item: Workspace.ItemID) {
        if hoveredItem == item { hoveredItem = nil }
        change { $0.select(item: item) }
    }
    package func selectNext() { step(by: 1) }
    package func selectPrevious() { step(by: -1) }
    package func select(index: Int) {
        let stops = self.stops
        if stops.indices.contains(index) { go(to: stops[index]) }
    }
    package func move(item: Workspace.ItemID, to index: Int) { change { $0.move(item: item, to: index) } }
    package func focus(_ pane: PaneID) {
        if let entry = favorites.favorites.entry(containing: pane) {
            favorites.edit { $0.focus(pane: pane) }
            showEntry(entry.id)
        } else {
            change { $0.focus(pane: pane) }
        }
    }
    package func focusNextPane() { change { $0.focusNext() } }
    package func focusPreviousPane() { change { $0.focusPrevious() } }
    package func drop(item: Workspace.ItemID, onto pane: PaneID, edge: PaneEdge) {
        change { $0.drop(item: item, onto: pane, edge: edge) }
    }
    package func movePane(_ pane: PaneID, beside target: PaneID, edge: PaneEdge) {
        change { $0.movePane(pane, beside: target, edge: edge) }
    }
    package func detachIntoTab(_ pane: PaneID) { change { $0.detach(pane: pane) } }
    package func setRatio(_ ratio: Double, at path: [SplitBranch], in item: Workspace.ItemID) {
        if let entry = shownEntry, entry.open?.id == item {
            favorites.edit { $0.setRatio(ratio, at: path, in: entry.id) }
        } else {
            change { $0.setRatio(ratio, at: path, in: item) }
        }
    }

    package func change(_ edit: (inout Workspace) -> Void) {
        let before = workspace
        edit(&workspace)
        if workspace != before {
            // Selecting a tab leaves the kept entry that was shown (`Workspace.show`): its panes are told so.
            if let entry = before.selectedEntry, workspace.selectedEntry != entry { left(entry) }
            syncStates()
            onChange()
        }
    }
}
