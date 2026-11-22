/// Where a tab, a pane or a kept entry being dragged could be dropped ("the target area show so that we know where to
/// drop tabs"): the views outline these from the start of the drag.
package struct DragTargets: Equatable, Sendable {
    /// The Pinned grid takes it (a tab or a favourite, with room).
    package var pinned: Bool
    /// The Favorites take it (a tab, a document, a pinned entry, a selection).
    package var favorites: Bool
    /// The panes take it (beside one, or as a split).
    package var panes: Bool
}
