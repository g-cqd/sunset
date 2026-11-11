package import SunsetPane

/// Folders (R3, t142): synthetic, only for tidying; they never open or close what they hold.
extension TabsModel {
    /// A new empty folder named "New Folder" at the end of the Favorites (or in `parent`); its name is edited at once.
    package func newFolder(in parent: Favorites.NodeID? = nil) {
        var made: Favorites.NodeID?
        favorites.edit { made = $0.addFolder(named: "New Folder", in: parent) }
        renamingRow = made.map(RowTarget.node)
    }

    /// Keeps the tab `item` in a new folder at the end of the Favorites; the folder's name is edited at once.
    package func newFolder(with item: Workspace.ItemID) {
        var made: Favorites.NodeID?
        favorites.edit { made = $0.addFolder(named: "New Folder") }
        guard let made else { return }
        keep(item: item, in: made)
        renamingRow = .node(made)
    }

    /// Deletes a folder and every entry in it; open ones stop, asking first when something runs in one of them.
    package func delete(folder id: Favorites.NodeID) {
        guard case .folder(let folder)? = favorites.favorites.node(id) else { return }
        let open = Self.entries(in: folder.children).compactMap(\.open)
        let busy = open.flatMap(\.panes).contains { favorites.contents[$0]?.closeWarning != nil }
        if let first = open.first { guard confirmed(.item(first.id), isBusy: busy) else { return } }
        favorites.delete(id)
        finishClosing()
    }

    /// Drops what is dragged into a folder, at its end: a tab is kept there, an entry or a folder moves there.
    @discardableResult
    package func dropDragged(intoFolder folder: Favorites.NodeID) -> Bool {
        if draggedSelection != nil { return dropSelection(into: folder) }
        guard let drag = dragged else { return false }
        switch drag {
            case .item(let item): keep(item: item, in: folder)
            case .entry(let id): favorites.edit { $0.move([id], into: folder, at: Int.max) }
            case .pane: return false
        }
        dragged = nil
        return true
    }

    /// Whether what is dragged can go into a folder.
    package func canDrop(intoFolder folder: Favorites.NodeID) -> Bool {
        switch dragged {
            case .item: true
            case .entry(let id): id != folder
            case .pane, nil: false
        }
    }

    private static func entries(in nodes: [Favorites.Node]) -> [Favorites.Entry] {
        nodes.flatMap { node -> [Favorites.Entry] in
            switch node {
                case .entry(let entry): [entry]
                case .folder(let folder): entries(in: folder.children)
            }
        }
    }
}
