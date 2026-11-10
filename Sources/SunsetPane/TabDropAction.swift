public import CoreGraphics

/// What dropping a tab or pane onto a tab row in the sidebar does, decided by where the pointer is inside the row: the top and bottom quarters reorder
/// before or after the row, and the middle half splits the row's tab on its left or right (`n25`).
public enum TabDropAction: Sendable, Equatable {
    case moveBefore
    case moveAfter
    case split(PaneEdge)

    public static func resolve(at point: CGPoint, in size: CGSize) -> TabDropAction {
        guard size.width > 0, size.height > 0 else { return .moveAfter }
        let ry = point.y / size.height
        if ry < 0.25 { return .moveBefore }
        if ry > 0.75 { return .moveAfter }
        return point.x < size.width / 2 ? .split(.left) : .split(.right)
    }
}
