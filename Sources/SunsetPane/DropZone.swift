public import CoreGraphics

/// Where a pane dropped on another goes: the four triangles cut by the diagonals of the target decide the edge nearest the pointer, and the preview is
/// the half of the target that the dropped pane would take.
public enum DropZone {
    /// The edge of `rect` nearest `point` (top-left origin): the diagonals of the rectangle, in its own proportions, separate the four zones. A point outside
    /// follows the same rule; an empty rectangle gives `.right`.
    public static func edge(at point: CGPoint, in rect: CGRect) -> PaneEdge {
        guard rect.width > 0, rect.height > 0 else { return .right }
        let dx = (point.x - rect.minX) / rect.width - 0.5
        let dy = (point.y - rect.minY) / rect.height - 0.5
        if abs(dx) > abs(dy) { return dx < 0 ? .left : .right }
        return dy < 0 ? .top : .bottom
    }

    /// The half of `rect` on `edge`.
    public static func preview(_ edge: PaneEdge, in rect: CGRect) -> CGRect {
        switch edge {
            case .left: CGRect(x: rect.minX, y: rect.minY, width: rect.width / 2, height: rect.height)
            case .right: CGRect(x: rect.midX, y: rect.minY, width: rect.width / 2, height: rect.height)
            case .top: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)
            case .bottom: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)
        }
    }
}
