public import SunsetConfig

/// Where the sidebar's resize handle is, along the window's horizontal axis, in points from the window's leading edge. All the measures are the sidebar's
/// column (`width`), the outer `margin` (`sidebar.padding`) and how far the tabs stop short of the column's edge (`tabSideInset`).
public enum SidebarHandle {
    /// The sidebar's width after dragging its handle by `drag` points to the right (negative: to the left): the handle is on the sidebar's inner edge, so on
    /// the left side dragging right widens it and on the right side dragging left does. Between 120 and 480 pt.
    public static func width(start: Double, drag: Double, side: Configuration.Side) -> Double {
        min(max(start + (side == .left ? drag : -drag), 120), 480)
    }

    /// The middle of the handle. Docked, that is the middle of the gap between the end of the tabs (`width - tabSideInset`) and the start of the terminal
    /// card (`width + margin`), so the grab area is visually between the two and not on the tabs. Floating there is no card: it is the middle between the
    /// end of the tabs and the panel's edge (`width`).
    public static func center(docked: Bool, width: Double, margin: Double, tabSideInset: Double) -> Double {
        let tabsEnd = width - tabSideInset
        let other = docked ? width + margin : width
        return (tabsEnd + other) / 2
    }

    /// The width of the hit box: as wide as asked, at least 2 pt to be grabbable, and floating no wider than the strip between the tabs and the panel's edge
    /// (the pointer leaving the panel would hide it).
    public static func hitWidth(docked: Bool, wanted: Double, tabSideInset: Double) -> Double {
        let width = max(wanted.isFinite ? wanted : 8, 2)
        return docked ? width : max(min(width, tabSideInset), 2)
    }
}
