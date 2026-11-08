public import CoreGraphics

/// A set of the four corners of a rectangle (top-left origin, `leading` is the left).
public struct CornerSet: OptionSet, Sendable, Equatable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let topLeading = CornerSet(rawValue: 1)
    public static let topTrailing = CornerSet(rawValue: 2)
    public static let bottomLeading = CornerSet(rawValue: 4)
    public static let bottomTrailing = CornerSet(rawValue: 8)
    public static let all: CornerSet = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
    public static let empty: CornerSet = []

    /// The corners of `frame` that lie on the corners of `bounds` (the area the panes share): the others touch another pane.
    public static func atCorners(of frame: CGRect, in bounds: CGRect, tolerance: Double = 0.5) -> CornerSet {
        let left = abs(frame.minX - bounds.minX) <= tolerance
        let right = abs(frame.maxX - bounds.maxX) <= tolerance
        let top = abs(frame.minY - bounds.minY) <= tolerance
        let bottom = abs(frame.maxY - bounds.maxY) <= tolerance
        var set = CornerSet.empty
        if top && left { set.insert(.topLeading) }
        if top && right { set.insert(.topTrailing) }
        if bottom && left { set.insert(.bottomLeading) }
        if bottom && right { set.insert(.bottomTrailing) }
        return set
    }
}
