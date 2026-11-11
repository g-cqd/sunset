package import SunsetPane

/// A tab was dropped on the edge of its own content, where there is no second terminal to split with yet: the app asks which other tab to put on the other
/// side. `pane` is the pane of the dragged tab the drop was over, and `edge` the side the dragged tab keeps.
package struct SplitChoice: Equatable {
    package let pane: PaneID
    package let edge: PaneEdge
}
