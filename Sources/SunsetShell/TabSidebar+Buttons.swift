import SwiftUI

/// The sidebar's buttons: the pin at the top, and the app's bar at the bottom mirroring it (same container, same gaps to the corner, concentric).
extension TabSidebar {
    /// The size and corner of a button in this sidebar: docked, flush with the card's top and the tabs' rhythm; floating, concentric with the panel.
    var buttonMetrics: SidebarButtonMetrics {
        SidebarButtonMetrics(
            size: panelRadius == nil
                ? CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight)
                : CGSize(width: layout.pinButtonSize, height: layout.pinButtonSize),
            radius: pinRadius,
            smooth: layout.smooth
        )
    }

    /// From the sidebar's edges to a button: the pin's gap, plus the docked container's inset.
    var buttonGap: Double { pinGap + (panelRadius == nil ? header.dockedButtonInset : 0) }

    var pinButton: some View {
        SidebarIconButton(
            symbol: "sidebar.left",
            filled: !settings.sidebar.autoHide,
            help: settings.sidebar.autoHide ? "Keep the sidebar visible" : "Let the sidebar hide",
            action: togglePin
        )
        .environment(\.sidebarButtonMetrics, buttonMetrics)
        .padding(settings.sidebar.side == .left ? .trailing : .leading, buttonGap)
        .padding(.top, panelRadius == nil ? header.dockedButtonInset : header.buttonTop)
    }

    /// The pin button's distance from the panel's top and from its edge: the same, so that their corners share a centre (docked: the container is flush with the terminal card's top and with the tabs' edge).
    var pinGap: Double { panelRadius == nil ? layout.tabSideInset : header.buttonTop }
    var pinRadius: Double {
        guard let panelRadius else { return layout.pinButtonRadius }
        return ConcentricRadius.inner(outer: panelRadius, inset: pinGap)
    }

    static let bottomBarHeight = 28.0

    /// How much room the rows leave at the bottom for the app's bar: a button's height and the tabs' spacing.
    var bottomInset: Double { bottomBar == nil ? 0 : buttonMetrics.size.height + layout.tabSpacing }

    /// The app's bar at the bottom, as the pin is at the top: the same gap to the side edges, and to the bottom (the card's bottom when docked).
    @ViewBuilder var bottomBarView: some View {
        if let bottomBar {
            bottomBar
                .environment(\.sidebarButtonMetrics, buttonMetrics)
                .frame(height: buttonMetrics.size.height)
                .padding(.horizontal, buttonGap)
                .padding(.bottom, panelRadius == nil ? margin + header.dockedButtonInset : header.buttonTop)
        }
    }
}
