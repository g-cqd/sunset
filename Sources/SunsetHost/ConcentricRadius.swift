/// Corners that share a centre. An inner shape inset from a rounded container by `inset` points has the container's radius minus the inset, so the two
/// curves stay a constant distance apart (the rule behind SwiftUI's `ConcentricRectangle`). Measured on macOS 27.0.1: the standard window's corner radius is
/// 16 pt (`NSWindow`'s `_cornerRadius`; the mask of the window measured from a screenshot fits 17 pt because the corner is continuous, not circular).
public enum ConcentricRadius {
    /// The radius of a window with a title bar or not, when it cannot be asked.
    public static let standardWindow = 16.0

    /// The inner corner radius, never below 0.
    public static func inner(outer: Double, inset: Double) -> Double {
        guard outer.isFinite, inset.isFinite else { return 0 }
        return max(outer - max(inset, 0), 0)
    }
}
