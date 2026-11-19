import SunsetMetrics
import SwiftUI

/// The sidebar's buttons: the pin at the top, and the app's bar at the bottom mirroring it (same container, same gaps to the corner, concentric).
extension TabSidebar {
    var buttons: SidebarButtons {
        SidebarButtons(layout: layout, margin: margin, panelRadius: panelRadius, windowRadius: windowRadius)
    }

    var pinButton: some View {
        SidebarPinButton(sidebar: settings.sidebar, buttons: buttons, toggle: togglePin)
    }

    /// How much room the rows leave at the bottom for the app's bar.
    var bottomInset: Double {
        bottomBar == nil ? 0 : buttons.barRoom(rows: bottomBarRows)
    }

    /// The app's bar at the bottom, as the pin is at the top: the same gap to the side edges, and to the bottom (the card's bottom when docked).
    @ViewBuilder var bottomBarView: some View {
        if let bottomBar {
            bottomBar
                .environment(\.sidebarButtonMetrics, buttons.metrics)
                .frame(height: buttons.barHeight(rows: bottomBarRows))
                .padding(.horizontal, buttons.gap)
                .padding(.bottom, buttons.bottom)
        }
    }
}
