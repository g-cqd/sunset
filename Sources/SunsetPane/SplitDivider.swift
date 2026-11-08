public import CoreGraphics

/// The line between the two parts of a split, as laid out in some bounds: where it is, which split it belongs to, and how to turn a pointer position into
/// the split's new ratio.
public struct SplitDivider: Sendable, Equatable {
    /// The path from the layout's root to the split this divider belongs to (empty: the root).
    public let path: [SplitBranch]
    public let axis: SplitAxis
    /// The space the whole split takes, both parts and the gap.
    public let container: CGRect
    /// The gap between the two parts (zero-sized along the axis when the layout has no gap).
    public let gap: CGRect
    let gapSize: Double

    /// The ratio the first part would have with the middle of the gap under `point`, kept at least `SplitLayout.minimumRatio` from either end.
    public func ratio(at point: CGPoint) -> Double {
        let origin = axis == .horizontal ? container.minX : container.minY
        let extent = axis == .horizontal ? container.width : container.height
        let position = axis == .horizontal ? point.x : point.y
        let usable = extent - gapSize
        guard usable > 0 else { return 0.5 }
        let raw = (position - origin - gapSize / 2) / usable
        return min(max(raw, SplitLayout.minimumRatio), 1 - SplitLayout.minimumRatio)
    }
}
