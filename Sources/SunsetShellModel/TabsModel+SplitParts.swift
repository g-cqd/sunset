package import SunsetPane

/// The parts of a split tab: a click on one shows the split and focuses that pane; any pane comes out into a tab of its
/// own, from Today, the Favorites or the grid.
extension TabsModel {
    /// Shows the split `row` (a tab of Today or a kept entry) with the keyboard in `pane`.
    package func choose(part pane: PaneID, of row: RowTarget) {
        switch row {
            case .tab(let id):
                if workspace.selectedID != id || shownEntry != nil { select(item: id) }
            case .node(let id):
                if shownEntry?.id != id { select(entry: id) }
        }
        focus(pane)
    }

    /// Takes every pane but the first of the split `item` (a tab of Today) out into tabs of their own, running: the split is
    /// undone, nothing closes.
    package func separateAll(item: Workspace.ItemID) {
        guard let split = workspace.items.first(where: { $0.id == item }), split.isSplit else { return }
        for pane in split.panes.dropFirst().reversed() { detachIntoTab(pane) }
    }

    /// Takes `pane` out of its split into a tab of its own, running: in Today, after its split; out of a kept entry, a tab
    /// of Today after the selected one, the entry keeping its other panes.
    package func separate(pane: PaneID) {
        if workspace.item(containing: pane) != nil {
            detachIntoTab(pane)
            return
        }
        guard let keeper = keeper(ofPane: pane), let content = keeper.separate(pane: pane) else { return }
        var tabs = workspace
        tabs.insert(pane: pane, at: tabs.selectedIndex.map { $0 + 1 } ?? tabs.count)
        contents[pane] = content
        wireContent(content)
        workspace = tabs
        syncStates()
        onChange()
    }
}
