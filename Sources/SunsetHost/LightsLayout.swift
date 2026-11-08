public import SunsetConfig

/// Where the three traffic light buttons go along the window's width: from the left edge in the system's order, or mirrored from the right edge (the close
/// button nearest the edge).
public enum LightsLayout {
    /// The x of the left edge of button `index` (0 close, 1 minimise, 2 zoom), in points from the window's left edge, with the buttons `inset` points from
    /// the edge they are on and `spacing` apart (left edge to left edge).
    public static func x(
        index: Int,
        side: Configuration.Side,
        inset: Double,
        windowWidth: Double,
        spacing: Double,
        buttonWidth: Double
    ) -> Double {
        switch side {
            case .left: inset + Double(index) * spacing
            case .right: windowWidth - inset - buttonWidth - Double(index) * spacing
        }
    }
}
