package import SwiftUI

/// Pins the sidebar beside the content (`sidebar.autoHide` off) or lets it hide and float: the sidebar half of a window, drawn
/// alone when it comes and goes, inset in its frame when it stays. Its container is a button of the sidebar, its trailing edge
/// on the tabs' trailing edge and its middle on the traffic lights'.
package struct SidebarPinButton: View {
    let sidebar: ShellSettings.Sidebar
    let buttons: SidebarButtons
    let toggle: () -> Void

    package init(sidebar: ShellSettings.Sidebar, buttons: SidebarButtons, toggle: @escaping () -> Void) {
        self.sidebar = sidebar
        self.buttons = buttons
        self.toggle = toggle
    }

    package var body: some View {
        let half = sidebar.side == .left ? "leadinghalf" : "trailinghalf"
        SidebarIconButton(
            symbol: sidebar.autoHide ? "rectangle.\(half).filled" : "inset.filled.\(half).rectangle",
            help: sidebar.autoHide ? "Keep the sidebar visible" : "Let the sidebar hide",
            action: toggle
        )
        .environment(\.sidebarButtonMetrics, buttons.metrics)
        .padding(sidebar.side == .left ? .trailing : .leading, buttons.gap)
        .padding(.top, buttons.top)
    }
}
