package import SwiftUI

extension View {
    /// A context menu in the menu's own ink (n140, n147). The window's accent is the tint of everything below its root, and a menu takes it:
    /// the symbols of a tab's menu, then of a pinned tab's and a favorite's, came up blue. `.tint(.primary)` on what the menu opens is the
    /// menu's own ink, set here once so that no menu has to remember it (`MenuInkTests` forbids a bare `.contextMenu`).
    package func inkedContextMenu<Menu: View>(@ViewBuilder _ menu: () -> Menu) -> some View {
        contextMenu {
            Group { menu() }.tint(.primary)
        }
    }
}
