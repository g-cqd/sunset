package import SunsetMetrics
import SwiftUI

/// Where the sidebar's buttons are and how big (the pin at the top, the app's bar at the bottom, the Library's rail): docked,
/// flush with the card's top and in the tabs' rhythm; floating, concentric with the panel.
package struct SidebarButtons {
    package let layout: ShellSettings.Layout
    package let margin: Double
    /// The floating panel's corner radius; nil when the sidebar is docked.
    package let panelRadius: Double?

    package init(layout: ShellSettings.Layout, margin: Double, panelRadius: Double?) {
        self.layout = layout
        self.margin = margin
        self.panelRadius = panelRadius
    }

    package var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: panelRadius != nil) }

    /// The size and corner of a button.
    package var metrics: SidebarButtonMetrics {
        SidebarButtonMetrics(
            size: panelRadius == nil
                ? CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight)
                : CGSize(width: layout.sidebarButtonSize, height: layout.sidebarButtonSize),
            radius: radius,
            smooth: layout.smooth
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

    /// From the sidebar's bottom to the app's bar (the card's bottom when docked).
    package var bottom: Double { panelRadius == nil ? margin + header.dockedButtonInset : header.buttonTop }
}
