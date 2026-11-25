package import SunsetPane

/// A drag that ends in another window than the one it started in. What is dragged is known to the window it started in
/// (`dragged`); the window it is over takes it up (`adoptDrag`), and, dropped, brings a tab of another Space to its own
/// (`bringDraggedHere`). The first window stays on its Space.
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
                // The pane of a split's row carries its tab; the pane alone does not leave its window.
                guard let item = origin.workspace.item(containing: pane) else { return false }
                dragged = .item(item.id)
            case .entry(let id):
                // The same entry where the profile is the same; another profile's comes as a tab.
                guard origin.keeper(of: id).favorites.entry(id) != nil else { return false }
                dragged = drag
        }
        return true
    }

    /// Dropped here: a tab of another Space comes to this one, running, at its end (the drop then puts it in its place); the
    /// window it came from forgets the drag.
    package func bringDraggedHere() {
        guard let origin = Self.dragOrigin, origin !== self else { return }
        // A kept entry of another profile leaves it as a tab first.
        if case .entry(let id) = dragged, case .foreignEntry? = dragSource, let item = origin.release(entry: id) {
            dragged = .item(item)
        }
        if case .item(let id) = dragged, !workspace.items.contains(where: { $0.id == id }) {
            origin.give(item: id, to: space)
            // From another profile (or an isolated unowned Space in tests where spaces == nil and favorites differ):
            // its pages load again under this Space's profile.
            let sameProfile =
                spaces != nil
                ? origin.space.space.profile == space.space.profile
                : origin.space.favorites === space.favorites
            if !sameProfile, let item = workspace.items.first(where: { $0.id == id }) {
                space.restart(kind: PaneDescriptor.webKind, panes: Set(item.panes), by: self)
            }
        }
        origin.dragged = nil
        Self.dragOrigin = nil
    }

    /// Extracts the live contents and unloaded pending descriptors for `panes` out of this Space.
    func takeContentsAndPending(for panes: [PaneID]) -> (
        contents: [PaneID: any PaneContent],
        pending: [PaneID: PaneDescriptor]
    ) {
        var moved: [PaneID: any PaneContent] = [:]
        var waiting: [PaneID: PaneDescriptor] = [:]
        for pane in panes {
            if let content = contents.removeValue(forKey: pane) {
                moved[pane] = content
            } else if let pending = space.pending.removeValue(forKey: pane) {
                waiting[pane] = pending
            }
        }
        return (moved, waiting)
    }

    /// Gives the tab `item` to another Space, running, without this window following it.
    package func give(item id: Workspace.ItemID, to other: SpaceModel) {
        guard other !== space else { return }
        var tabs = workspace
        guard let item = tabs.take(item: id) else { return }
        let extracted = takeContentsAndPending(for: item.panes)
        workspace = tabs
        other.adopt([item], contents: extracted.contents, pending: extracted.pending)
        syncStates()
        onChange()
    }
}
