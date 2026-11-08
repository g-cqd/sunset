/// The direction a split lays its two parts out in.
public enum SplitAxis: String, Sendable, Equatable, Codable {
    /// Side by side: the first part on the left.
    case horizontal
    /// One above the other: the first part on top.
    case vertical
}
