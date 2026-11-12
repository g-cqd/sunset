import SunsetMetrics
import SwiftUI

/// The app's accessory at the top of the sidebar, under the window's buttons (the address of the focused page, web step b).
extension TabSidebar {
    static let accessoryHeight = 26.0

    /// How much further down the rows start for it: its height and a gap; nothing without one.
    var accessoryInset: Double { accessory == nil ? 0 : Self.accessoryHeight + layout.tabSpacing + 4 }

    @ViewBuilder var accessoryView: some View {
        if let accessory {
            accessory
                .frame(height: Self.accessoryHeight)
                .padding(
                    .top,
                    SidebarHeader(layout: layout, margin: settings.sidebar.padding, floating: floating).height
                )
                .padding(.horizontal, layout.tabSideInset)
        }
    }
}
