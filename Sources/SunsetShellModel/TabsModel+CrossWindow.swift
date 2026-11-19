package import SunsetPane

/// A drag that ends in another window than the one it started in (roadmap 0036 F). What is dragged is known to the window it
/// started in (`dragged`); the window it is over takes it up (`adoptDrag`), and, dropped, brings a tab of another Space to its
/// own (`bringDraggedHere`). The first window stays on its Space.
extension TabsModel {
    /// The window the drag under way started in (observed: every window's drop places show while it is set).
    package internal(set) static var dragOrigin: TabsModel? {
        get {
            DragUnderWay.shared.origin
        }
        set {
            DragUnderWay.shared.origin = newValue
        }
    }

    /// Whether a drag of tabs is under way over this window, started here or in another window (taken up then).
    package var hasDrag: Bool {
        adoptDrag()
    }

    /// Takes up a drag that started in another window, to be asked about and dropped here; true when there is one here now.
    @discardableResult
    package func adoptDrag() -> Bool {
        if dragged != nil { return true }
        guard let origin = Self.dragOrigin, origin !== self, let drag = origin.dragged else { return false }
        switch drag {
            case .item, .document:
                dragged = drag
            case .pane(let pane):
                // The pane of a split's row carries its tab (ADR-0062); the pane alone does not leave its window.
                guard let item = origin.workspace.item(containing: pane) else { return false }
                dragged = .item(item.id)
            case .entry(let id):
                // The same entry where the profile is the same; another profile's comes as a tab (roadmap 0037 B).
                guard origin.keeper(of: id).favorites.entry(id) != nil else { return false }
                dragged = drag
        }
        return true
    }

    /// Dropped here: a tab of another Space comes to this one, running, at its end (the drop then puts it in its place); the
    /// window it came from forgets the drag.
    package func bringDraggedHere() {
        guard let origin = Self.dragOrigin, origin !== self else { return }
        // A kept entry of another profile leaves it as a tab first (roadmap 0037 B).
        if case .entry(let id) = dragged, case .foreignEntry? = dragSource, let item = origin.release(entry: id) {
            dragged = .item(item)
        }
        if case .item(let id) = dragged, !workspace.items.contains(where: { $0.id == id }) {
            origin.give(item: id, to: space)
            // From another profile: its pages load again as this one's (as a Space given another profile, ADR-0053).
            if origin.space.favorites !== space.favorites, let item = workspace.items.first(where: { $0.id == id }) {
                space.restart(kind: "web", panes: Set(item.panes), by: self)
            }
        }
        origin.dragged = nil
        Self.dragOrigin = nil
    }

    /// Gives the tab `item` to another Space, running, without this window following it.
    package func give(item id: Workspace.ItemID, to other: SpaceModel) {
        guard other !== space else { return }
        var tabs = workspace
        guard let item = tabs.take(item: id) else { return }
        var moved: [PaneID: any PaneContent] = [:]
        for pane in item.panes { moved[pane] = contents.removeValue(forKey: pane) }
        workspace = tabs
        other.adopt([item], contents: moved, pending: [:])
        syncStates()
        onChange()
    }
}
