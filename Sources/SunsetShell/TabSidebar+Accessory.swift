import SunsetMetrics
import SwiftUI

/// The app's accessory at the top of the sidebar, under the window's buttons: the address of the focused page, or the field
/// where a search, an address or a command is typed (web step b; roadmap 0035 G).
extension TabSidebar {
    /// A tab's row: the field is as tall as one (the owner, 2026-11-17, roadmap 0035 G).
    var accessoryHeight: Double { Design.oneLineHeight(layout, height: Design.Size.tabRow) }

    /// How much further down the rows start for it: its height and the gap between two rows; nothing without one.
    var accessoryInset: Double { accessory == nil ? 0 : accessoryHeight + layout.tabSpacing }

    @ViewBuilder var accessoryView: some View {
        if let accessory {
            accessory
                // A tab's corner and its leading padding (roadmap 0035 G).
                .environment(\.controlRadius, layout.tabRadius)
                .environment(\.controlPadding, layout.tabPaddingLeading)
                .environment(\.controlHeight, accessoryHeight)
                .frame(height: accessoryHeight)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                    if !isPreview { tabs.sidebarField = frame }
                }
                .onDisappear { if !isPreview { tabs.sidebarField = nil } }
                .padding(
                    .top,
                    SidebarHeader(layout: layout, margin: settings.sidebar.padding, floating: floating).height
                )
                .padding(.horizontal, layout.tabSideInset)
        }
    }
}
