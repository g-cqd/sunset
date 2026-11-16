package import SunsetPane

/// Closing what the person asked to close: a running command is confirmed first (the tab goes red, `n28`), then unsaved edits
/// are asked about (`losingNothing`), then it closes.
extension TabsModel {
    /// User-initiated request to close a pane: when a command is running in it, arms its tab for confirmation first (`n28`). A pane of a kept entry
    /// closes the same way, and its last pane unloads the entry (it stays in the Favorites).
    package func requestClose(pane: PaneID) {
        if let entry = favorites.favorites.entry(containing: pane), let item = entry.open, let model = content(pane) {
            guard confirmed(.pane(pane, in: item.id), isBusy: model.closeWarning != nil) else { return }
            return losingNothing(closing: [pane]) { [self] in
                favorites.close(pane: pane)
                syncStates()
            }
        }
        guard let item = workspace.item(containing: pane)?.id, let model = contents[pane] else { return }
        guard confirmed(.pane(pane, in: item), isBusy: model.closeWarning != nil) else { return }
        losingNothing(closing: [pane]) { [self] in close(pane: pane) }
    }

    /// Closes a tab with all its panes (asking for confirmation first when any of its panes has a command running).
    package func close(item: Workspace.ItemID) {
        if hoveredItem == item { hoveredItem = nil }
        guard let target = workspace.items.first(where: { $0.id == item }) else { return }
        guard confirmed(.item(item), isBusy: target.panes.contains { contents[$0]?.closeWarning != nil }) else {
            return
        }
        losingNothing(closing: target.panes) { [self] in
            stop(workspace.close(item: item))
            finishClosing()
        }
    }

    /// Closes every tab but `item`, asking first when a command is running in one of them (they go red).
    package func closeOthers(than item: Workspace.ItemID) {
        let others = workspace.items.filter { $0.id != item }.flatMap(\.panes)
        guard confirmed(.others(item), isBusy: others.contains { contents[$0]?.closeWarning != nil }) else { return }
        losingNothing(closing: others) { [self] in
            stop(workspace.closeOthers(than: item))
            syncStates()
            onChange()
        }
    }

    /// Closes the focused pane (the tab with its last pane; a kept entry is unloaded with its last pane).
    package func closeSelected() { if let pane = shownPane { requestClose(pane: pane) } }
}
