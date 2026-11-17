package import SunsetPane

/// Dropping what is dragged in a section of the sidebar (roadmap 0035 A): a tab of Today, a pane of a split (its whole split),
/// a favourite, a folder, a tile of the Pinned grid, a document; in the grid, the Favorites or Today, at a place.
extension TabsModel {
    /// What is dragged, by where it comes from.
    enum DragSource: Equatable {
        case tab(Workspace.ItemID)
        case favorite(Favorites.NodeID)
        case folder(Favorites.NodeID)
        case tile(Favorites.NodeID)
        case document
    }

    /// What is dragged, by where it comes from; a pane of a split is its whole tab (the owner: "the container itself").
    var dragSource: DragSource? {
        switch dragged {
            case .item(let id): return .tab(id)
            case .pane(let pane):
                if let item = workspace.item(containing: pane) { return .tab(item.id) }
                return keeper(ofPane: pane)?.favorites.entry(containing: pane)
                    .map { isPinned($0.id) ? .tile($0.id) : .favorite($0.id) }
            case .entry(let id):
                if isPinned(id) { return .tile(id) }
                switch favorites.favorites.node(id) {
                    case .entry: return .favorite(id)
                    case .folder: return .folder(id)
                    case nil: return nil
                }
            case .document: return .document
            case nil: return nil
        }
    }

    /// Whether what is dragged can be dropped at `place`.
    package func canDropDragged(in place: SectionDrop) -> Bool {
        adoptDrag()
        guard let source = dragSource else { return false }
        switch (source, place) {
            case (.tile, .pinned): return true
            case (.tab, .pinned), (.favorite, .pinned): return canPin
            case (.folder, .pinned), (.document, .pinned): return false
            case (.folder(let id), .favorites(let parent, _)):
                // Not into itself, nor into a folder it holds.
                guard let parent else { return true }
                return parent != id && !Self.holds(favorites.favorites.node(id), parent)
            case (_, .favorites): return true
            case (.folder, .today): return false
            case (_, .today): return true
        }
    }

    /// Drops what is dragged at `place`; false when it cannot go there.
    @discardableResult
    package func dropDragged(in place: SectionDrop) -> Bool {
        guard canDropDragged(in: place) else { return false }
        bringDraggedHere()
        takeDocumentDrag()
        guard let source = dragSource else { return false }
        dragged = nil
        switch (source, place) {
            case (.tab(let id), .pinned(let index)):
                return pin(item: id, show: false, at: index) != nil
            case (.favorite(let id), .pinned(let index)):
                return pin(entry: id, at: index)
            case (.tile(let id), .pinned(let index)):
                pinned?.edit { $0.move([id], into: nil, at: Self.place(index, for: id, in: nil, of: $0)) }
                onChange()
                return true
            case (.tab(let id), .favorites(let parent, let index)):
                return keep(item: id, in: parent, at: index, show: false) != nil
            case (.favorite(let id), .favorites(let parent, let index)),
                (.folder(let id), .favorites(let parent, let index)):
                favorites.edit { $0.move([id], into: parent, at: Self.place(index, for: id, in: parent, of: $0)) }
                onChange()
                return true
            case (.tile(let id), .favorites(let parent, let index)):
                return favorite(pinned: id, in: parent, at: index)
            case (.tab(let id), .today(let index)):
                guard let from = workspace.items.firstIndex(where: { $0.id == id }) else { return false }
                change { $0.move(item: id, to: from < index ? index - 1 : index) }
                return true
            case (.favorite(let id), .today(let index)), (.tile(let id), .today(let index)):
                release(entry: id, at: index)
                return true
            case (.folder, _), (.document, _), (.tab, _), (.favorite, _), (.tile, _):
                return false
        }
    }

    /// The place to give `move` for `id` to land at `index` of `parent` as it is now: one less when it comes from before it in
    /// the same folder (the place counts among what is left once it is out); the end for nil.
    private static func place(_ index: Int?, for id: Favorites.NodeID, in parent: Favorites.NodeID?, of tree: Favorites)
        -> Int
    {
        guard let index else { return Int.max }
        guard let from = tree.location(of: id), from.parent == parent, from.index < index else { return index }
        return index - 1
    }

    /// Whether `node` holds the folder `id`, at any depth.
    private static func holds(_ node: Favorites.Node?, _ id: Favorites.NodeID) -> Bool {
        guard case .folder(let folder) = node else { return false }
        return folder.children.contains { $0.id == id || holds($0, id) }
    }
}
