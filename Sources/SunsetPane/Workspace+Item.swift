import Foundation

/// The edits of one tab's layout, shared by a window's tabs (`Workspace`) and the kept entries that are open (`Favorites`).
extension Workspace.Item {
    /// Puts `new` on `edge` of the pane `target`.
    mutating func insert(_ new: SplitLayout, beside target: PaneID, edge: PaneEdge) {
        layout = layout.inserting(new, beside: target, edge: edge)
    }

    /// Takes `pane` out: its space goes to its sibling, and the keyboard to a pane that is left when it had it. False, and nothing changed, when it is
    /// the only pane (the tab itself goes then) or is not there.
    mutating func remove(_ pane: PaneID) -> Bool {
        guard layout.contains(pane), let rest = layout.removing(pane) else { return false }
        let position = panes.firstIndex(of: pane) ?? 0
        layout = rest
        if focused == pane { focused = rest.panes[min(position, rest.panes.count - 1)] }
        return true
    }
}
