package import SunsetPane

extension FavoritesModel {
    /// Makes the place an entry starts from what it is now (`Set Home to Current`).
    package func setHomeToCurrent(_ id: Favorites.NodeID) {
        guard let open = favorites.entry(id)?.open else { return }
        let descriptors = open.panes.reduce(into: [PaneID: PaneDescriptor]()) { $0[$1] = contents[$1]?.descriptor }
        edit { $0.setHome(Favorites.Home(layout: open.layout, focused: open.focused, contents: descriptors), for: id) }
    }

    package func addPane(beside target: PaneID, edge: PaneEdge, content: any PaneContent) -> Bool {
        var pane: PaneID?
        edit { pane = $0.addPane(beside: target, edge: edge) }
        guard let pane else { return false }
        content.onExit = { [weak self] in self?.paneEnded(pane) }
        contents[pane] = content
        return true
    }

    /// Inserts `layout` on `edge` of `target` in the open entry that holds `target`, adopting `moved` contents for its
    /// panes and focusing `focused`.
    package func insertLayout(
        _ layout: SplitLayout,
        focused: PaneID,
        beside target: PaneID,
        edge: PaneEdge,
        contents moved: [PaneID: any PaneContent]
    ) -> Bool {
        var inserted = false
        edit { inserted = $0.insertLayout(layout, focused: focused, beside: target, edge: edge) }
        guard inserted else { return false }
        for (pane, content) in moved {
            content.onExit = { [weak self] in self?.paneEnded(pane) }
            contents[pane] = content
        }
        return true
    }

    /// Closes one pane of an open entry, as asked; the entry is unloaded, and kept, with its last pane.
    package func close(pane: PaneID) {
        guard let id = favorites.entry(containing: pane)?.id else { return }
        var unloaded = false
        edit { unloaded = $0.close(pane: pane) }
        stop([pane])
        if unloaded { released(id) }
    }

    /// Takes one pane out of an open entry's split, running: its content, handed to whoever takes the pane; nil when the
    /// entry does not hold it with another.
    package func separate(pane: PaneID) -> (any PaneContent)? {
        var taken = false
        edit { taken = $0.separate(pane: pane) }
        guard taken else { return nil }
        pending[pane] = nil
        return contents.removeValue(forKey: pane)
    }

    /// A program in an entry's pane ended by itself.
    package func paneEnded(_ pane: PaneID) {
        close(pane: pane)
    }

    func stop(_ panes: [PaneID]) {
        for pane in panes {
            contents.removeValue(forKey: pane)?.stop()
            pending[pane] = nil
        }
    }
}
