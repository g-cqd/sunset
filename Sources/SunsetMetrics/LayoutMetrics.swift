/// The measures of the sidebar, the tabs, the traffic lights and the cards (`layout.*`), in points unless said otherwise: the one list, read by the
/// configuration (`Configuration.Layout`) and drawn by the shell (`ShellSettings.Layout`), so that a measure is declared once (design 0003 §7).
public struct LayoutMetrics: Sendable, Equatable {
    public var tabSpacing = 4.0
    public var tabSideInset = 2.0
    public var tabPaddingLeading = 8.0
    public var tabPaddingTrailing = 4.0
    public var tabPaddingVertical = 3.0
    public var tabRadius = 6.0
    public var closeButtonSize = 20.0
    public var closeButtonRadius = 4.0
    /// The tab metrics of the floating panel (it can look different from the docked sidebar): spacing 3 (half of what it was), the rest as the docked ones were.
    public var floatingTabSpacing = 3.0
    public var floatingTabSideInset = 4.0
    public var floatingTabPaddingLeading = 8.0
    public var floatingTabPaddingTrailing = 4.0
    public var floatingTabPaddingVertical = 3.0
    public var floatingTabRadius = 6.0
    public var floatingCloseButtonSize = 20.0
    public var floatingCloseButtonRadius = 4.0
    /// Width of the strip that resizes the sidebar by dragging.
    public var resizeHandleWidth = 8.0
    public var lightsInset = 8.0
    public var lightsGap = 10.0
    public var floatingLightsExtra = 0.0
    /// The sidebar's buttons (the pin, the +, downloads): the floating panel's size (docked, they are as tall as the lights' row makes them) and the
    /// docked corner (floating, it is concentric with the panel). Read also as `pinButtonSize` / `pinButtonRadius`, the names before 2026-11-12.
    public var sidebarButtonSize = 24.0
    public var sidebarButtonRadius = 5.0
    public var hairlineWidth = 0.5
    public var hairlineOpacity = 0.12
    public var revealStripWidth = 10.0
    /// The space between the panes of a split (and between them and the window's edge) when the sidebar is not docked, in points; with it docked the space is the
    /// sidebar's `padding`, so that the cards are framed alike.
    public var paneGap = 2.0
    /// The radius of a terminal card's corners that are next to the sidebar or to another pane (tighter than the ones at the window's corners, which follow
    /// the window's radius).
    public var innerCornerRadius = 6.0
    /// Seconds the floating sidebar stays after the pointer leaves it.
    public var hideDelay = 0.35
    /// Seconds of the one transition between states (hover, selection, pinning).
    public var animation = 0.15
    /// Corner radius of the terminal card while the sidebar is docked; nil: concentric with the window's corners (the window's radius minus the margin).
    public var terminalRadius: Double?
    /// Corner radius of the floating panel; nil: concentric with the window's corners.
    public var panelRadius: Double?

    public init() {}

    /// The layout with the tab metrics the floating panel draws with (its own `floatingTab*` and `floatingCloseButton*`) in place of the docked ones.
    public var floatingTabs: Self {
        var copy = self
        copy.tabSpacing = floatingTabSpacing
        copy.tabSideInset = floatingTabSideInset
        copy.tabPaddingLeading = floatingTabPaddingLeading
        copy.tabPaddingTrailing = floatingTabPaddingTrailing
        copy.tabPaddingVertical = floatingTabPaddingVertical
        copy.tabRadius = floatingTabRadius
        copy.closeButtonSize = floatingCloseButtonSize
        copy.closeButtonRadius = floatingCloseButtonRadius
        return copy
    }
}
