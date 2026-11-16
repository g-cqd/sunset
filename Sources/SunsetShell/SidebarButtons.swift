package import SunsetMetrics
import SwiftUI

/// Where the sidebar's buttons are and how big (the pin at the top, the app's bar at the bottom, the Library's rail): docked,
/// flush with the card's top and in the tabs' rhythm; floating, concentric with the panel.
package struct SidebarButtons {
    package let layout: ShellSettings.Layout
    package let margin: Double
    /// The floating panel's corner radius; nil when the sidebar is docked.
    package let panelRadius: Double?
    /// The window's corner radius: docked, the button at its bottom corner is concentric with it.
    package let windowRadius: Double

    package init(
        layout: ShellSettings.Layout,
        margin: Double,
        panelRadius: Double?,
        windowRadius: Double = ConcentricRadius.standardWindow
    ) {
        self.layout = layout
        self.margin = margin
        self.panelRadius = panelRadius
        self.windowRadius = windowRadius
    }

    package var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: panelRadius != nil) }

    /// The size and corner of a button.
    package var metrics: SidebarButtonMetrics {
        SidebarButtonMetrics(
            size: panelRadius == nil
                ? CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight)
                : CGSize(width: layout.sidebarButtonSize, height: layout.sidebarButtonSize),
            radius: radius,
            smooth: layout.smooth,
            windowCorner: windowCorner
        )
    }

    /// The pin's distance from the panel's top and from its edge: the same, so that their corners share a centre (docked: the
    /// container is flush with the terminal card's top).
    package var pinGap: Double { panelRadius == nil ? layout.tabSideInset : header.buttonTop }

    package var radius: Double {
        guard let panelRadius else { return layout.sidebarButtonRadius }
        return ConcentricRadius.inner(outer: panelRadius, inset: pinGap)
    }

    /// From the sidebar's side edges to a button: the pin's gap, plus the docked container's inset.
    package var gap: Double { pinGap + (panelRadius == nil ? header.dockedButtonInset : 0) }

    /// From the sidebar's top to the pin.
    package var top: Double { panelRadius == nil ? header.dockedButtonInset : header.buttonTop }

    /// The corner of a button that is at the window's bottom corner: docked, it shares its centre with the window's, the
    /// button being as far from the window's side as from its bottom (`bottom`); never sharper than the button's own. Floating,
    /// every corner is already concentric with the panel.
    package var windowCorner: Double {
        guard panelRadius == nil else { return radius }
        return max(radius, ConcentricRadius.inner(outer: windowRadius, inset: bottom))
    }

    /// From the sidebar's bottom, which is the window's, to the app's bar. Docked, as far as the buttons are from the window's
    /// side (the owner, 2026-11-15, A1): that is `lift` above the card's bottom, where the bar was.
    package var bottom: Double { panelRadius == nil ? margin + gap : header.buttonTop }

    /// How much higher than flush with the card's bottom the docked bar is.
    package var lift: Double { panelRadius == nil ? gap - header.dockedButtonInset : 0 }

    /// The room the rows leave the bar at the bottom: a button's height and the tabs' spacing, and what the bar is lifted by.
    package var barRoom: Double { metrics.size.height + layout.tabSpacing + lift }
}
