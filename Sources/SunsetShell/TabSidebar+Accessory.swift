import SunsetMetrics
import SwiftUI

/// The app's accessory at the top of the sidebar, under the window's buttons: the address of the focused page, or the field
/// where a search, an address or a command is typed.
extension TabSidebar {
    /// A tab's row: the field is as tall as one.
    var accessoryHeight: Double {
        Design.oneLineHeight(layout, height: Design.Size.tabRow)
    }

    /// How much further down the rows start for it: its height and the gap between two rows; nothing without one.
    var accessoryInset: Double {
        accessory == nil ? 0 : accessoryHeight + layout.tabSpacing
    }

    /// How much further down the rows start for the calls to action: their height and a row's gap; nothing without any.
    var noticesInset: Double {
        notices == nil || noticesHeight == 0 ? 0 : noticesHeight + layout.tabSpacing
    }

    /// The calls to action, under the accessory.
    @ViewBuilder var noticesView: some View {
        if let notices {
            notices
                .onGeometryChange(for: Double.self, of: { Double($0.size.height) }) { noticesHeight = $0 }
                .padding(
                    .top,
                    SidebarHeader(layout: layout, margin: settings.sidebar.padding, floating: floating).height
                        + accessoryInset
                )
                .padding(.horizontal, layout.tabSideInset)
        }
    }

    @ViewBuilder var accessoryView: some View {
        if let accessory {
            accessory
                // A tab's corner and its leading padding.
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
