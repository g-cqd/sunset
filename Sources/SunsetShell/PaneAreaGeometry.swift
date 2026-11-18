/// How the panes of a tab sit in the window (the owner, 2026-11-18): the margin around them, the space between them, and
/// the radius of their corners at the window's corners and elsewhere.
///
/// In a window, as before: cards with the sidebar docked or the tab split, `margin` (docked) or `paneGap` around and between
/// them, their corners concentric with the window's. In full screen, nothing around the content: one pane fills the screen,
/// to the docked sidebar if there is one; two panes side by side or one above the other go to the screen's edges with
/// `paneGap` between them, rounded only where they face each other; three or more (a grid) have the window's margins back,
/// and a radius everywhere, never 0.
package struct PaneAreaGeometry: Equatable, Sendable {
    /// Around the panes.
    package var inset: Double
    /// Between two panes.
    package var gap: Double
    /// The panes are cards (rounded, outlined).
    package var isCard: Bool
    /// At the window's (the area's) corners.
    package var outerRadius: Double
    /// Where a card is next to another or to the sidebar.
    package var innerRadius: Double

    /// The window's measures the geometry is made from.
    package struct Measures: Equatable, Sendable {
        /// The sidebar's margin.
        package var margin: Double
        /// The space between the panes of a split.
        package var paneGap: Double
        /// The window's corner radius (0: not known, or full screen).
        package var windowRadius: Double
        /// The radius the configuration sets, if it does.
        package var terminalRadius: Double?
        /// The radius of a corner next to another card.
        package var innerCornerRadius: Double

        package init(
            margin: Double,
            paneGap: Double,
            windowRadius: Double,
            terminalRadius: Double?,
            innerCornerRadius: Double
        ) {
            self.margin = margin
            self.paneGap = paneGap
            self.windowRadius = windowRadius
            self.terminalRadius = terminalRadius
            self.innerCornerRadius = innerCornerRadius
        }
    }

    /// - Parameters:
    ///   - fullScreen: the window is full screen.
    ///   - docked: the sidebar is docked (fixed beside the content).
    ///   - panes: how many panes the tab shows.
    ///   - measures: the window's margins and radii.
    /// - Returns: where the panes sit and how round they are.
    package static func make(fullScreen: Bool, docked: Bool, panes: Int, measures: Measures) -> Self {
        let margin = measures.margin
        let paneGap = measures.paneGap
        let windowRadius = measures.windowRadius
        let terminalRadius = measures.terminalRadius
        let innerCornerRadius = measures.innerCornerRadius
        // A window has round corners: a radius read as 0 is one read in full screen, or before the window had one.
        let window = windowRadius > 0 ? windowRadius : ConcentricRadius.standardWindow
        func card(_ space: Double, inset: Double) -> Self {
            let outer = terminalRadius ?? ConcentricRadius.inner(outer: window, inset: space)
            return Self(
                inset: inset,
                gap: space,
                isCard: true,
                outerRadius: outer,
                innerRadius: min(innerCornerRadius, outer)
            )
        }
        let standard = docked ? margin : paneGap
        guard fullScreen else {
            guard docked || panes > 1 else {
                return Self(
                    inset: 0,
                    gap: 0,
                    isCard: false,
                    outerRadius: window,
                    innerRadius: min(innerCornerRadius, window)
                )
            }
            return card(standard, inset: standard)
        }
        switch panes {
            case ...1: return Self(inset: 0, gap: 0, isCard: false, outerRadius: 0, innerRadius: 0)
            case 2: return Self(inset: 0, gap: paneGap, isCard: true, outerRadius: 0, innerRadius: innerCornerRadius)
            default: return card(standard, inset: standard)
        }
    }
}
