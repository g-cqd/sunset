import SunsetMetrics
import SwiftUI

/// The sidebar's buttons: the pin at the top, and the app's bar at the bottom mirroring it (same container, same gaps to the corner, concentric).
extension TabSidebar {
    var buttons: SidebarButtons {
        SidebarButtons(layout: layout, margin: margin, panelRadius: panelRadius, windowRadius: windowRadius)
    }

    /// The pin, and beside it, toward the traffic lights, what the app puts there (the extensions' buttons).
    var pinButton: some View {
        HStack(alignment: .top, spacing: Design.Space.xs) {
            if settings.sidebar.side == .left { extras }
            SidebarPinButton(sidebar: settings.sidebar, buttons: buttons, toggle: togglePin)
            if settings.sidebar.side == .right { extras }
        }
    }

    @ViewBuilder private var extras: some View {
        if let headerExtras {
            headerExtras
                .environment(\.sidebarButtonMetrics, buttons.metrics)
                .padding(.top, buttons.top)
        }
    }

    /// How much room the rows leave at the bottom for the app's bar.
    var bottomInset: Double {
        (bottomBar == nil ? 0 : buttons.barRoom(rows: bottomBarRows))
            + (footer == nil || footerHeight == 0 ? 0 : footerHeight + layout.tabSpacing)
    }

    /// The app's bar at the bottom, as the pin is at the top: the same gap to the side edges, and to the bottom (the card's bottom when docked).
    @ViewBuilder var bottomBarView: some View {
        if let bottomBar {
            VStack(spacing: layout.tabSpacing) {
                if let footer {
                    footer.onGeometryChange(for: Double.self) {
                        $0.size.height
                    } action: {
                        footerHeight = $0
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomBar
                    .environment(\.sidebarButtonMetrics, buttons.metrics)
                    .frame(height: buttons.barHeight(rows: bottomBarRows))
            }
            .padding(.horizontal, buttons.gap)
            .padding(.bottom, buttons.bottom)
            .animation(.smooth, value: footer == nil)
        }
    }

    /// Where the Library is to swipe to: past the first Space for a sidebar on the left, the last for one on the right,
    /// while the Library is offered.
    var swipeLibrary: SpaceSwipe.LibrarySide? {
        guard settings.sidebar.library, SidebarSection.rail(for: tabs.scopes).count > 1 else { return nil }
        return settings.sidebar.side == .left ? .previous : .next
    }
}
