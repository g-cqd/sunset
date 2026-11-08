/// A side of a pane or of the window's content: where a dropped pane goes, and the direction of a move between panes.
public enum PaneEdge: Sendable, Equatable, CaseIterable {
    case left, right, top, bottom

    /// The axis of a split that puts something on this edge.
    public var axis: SplitAxis { self == .left || self == .right ? .horizontal : .vertical }

    /// A thing placed on this edge is the first part of the split (left, top).
    public var placesFirst: Bool { self == .left || self == .top }
}
