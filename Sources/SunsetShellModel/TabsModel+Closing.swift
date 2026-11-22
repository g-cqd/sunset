package import SunsetPane

/// Closing what the person asked to close: a running command is confirmed first (the tab goes red), then unsaved edits
/// are asked about (`losingNothing`), then it closes.
extension TabsModel {
    /// User-initiated request to close a pane: when a command is running in it, arms its tab for confirmation first. A pane of a kept entry
    /// closes the same way, and its last pane unloads the entry (it stays in the Favorites).
    package func requestClose(pane: PaneID) {
        if let favorites = keeper(ofPane: pane), let entry = favorites.favorites.entry(containing: pane),
            let item = entry.open, let model = content(pane)
        {
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

    /// Closes a pane immediately (used when its program exits on its own).
    package func close(pane: PaneID) {
        guard let model = contents[pane] else { return }
        if let item = workspace.item(containing: pane)?.id, isCloseArmed(item) { closeConfirmation.disarm() }
        if hoveredPane == pane { hoveredPane = nil }
        let back = goingBack(closingLastOf: pane)
        workspace.close(pane: pane)
        back?()
        contents[pane] = nil
        model.stop()
        finishClosing()
    }

    /// Closes a tab with all its panes (asking for confirmation first when any of its panes has a command running).
    package func close(item: Workspace.ItemID) {
        if hoveredItem == item { hoveredItem = nil }
        guard let target = workspace.items.first(where: { $0.id == item }) else { return }
        guard confirmed(.item(item), isBusy: target.panes.contains { contents[$0]?.closeWarning != nil }) else {
            return
        }
        losingNothing(closing: target.panes) { [self] in
            let back = closeGoesBack && selectedID == item ? previouslyShown(before: item) : nil
            stop(workspace.close(item: item))
            shownBefore.removeAll { $0 == item }
            if let back { select(item: back) }
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
    package func closeSelected() {
        if let pane = shownPane { requestClose(pane: pane) }
    }

    /// The tab this window showed last before `item`, still among the Space's.
    package func previouslyShown(before item: Workspace.ItemID) -> Workspace.ItemID? {
        let open = Set(workspace.items.map(\.id))
        return shownBefore.last { $0 != item && open.contains($0) }
    }

    /// Keeps `shown` last of the tabs this window showed.
    package func remember(_ shown: Workspace.ItemID?, was: Workspace.ItemID?) {
        guard let shown, shown != was else { return }
        shownBefore.removeAll { $0 == shown }
        shownBefore.append(shown)
    }

    /// When `pane` is the last of the shown tab: what shows the tab shown before it, once the tab is closed.
    package func goingBack(closingLastOf pane: PaneID) -> (() -> Void)? {
        guard closeGoesBack, let tab = workspace.item(containing: pane), tab.panes.count == 1, tab.id == selectedID,
            let back = previouslyShown(before: tab.id)
        else { return nil }
        return { [self] in
            shownBefore.removeAll { $0 == tab.id }
            select(item: back)
        }
    }
}
