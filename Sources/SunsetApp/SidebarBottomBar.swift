import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// The bottom of the sidebar (R2's + button, t137, and web step f), mirroring the pin at the top: the + on the corner nearest the panes (the owner's
/// sketch E), downloads at the other corner while there are any; both the sidebar's buttons (`SidebarIconButton`). A click on + makes a tab of the
/// focused kind; its menu (right-click or long press) has every kind.
struct SidebarBottomBar: View {
    let side: Configuration.Side
    private let downloads = DownloadCenter.shared

    init(side: Configuration.Side) { self.side = side }

    var body: some View {
        HStack(spacing: 0) {
            if side == .left { downloadsButton } else { plus }
            Spacer(minLength: 0)
            if side == .left { plus } else { downloadsButton }
        }
    }

    @ViewBuilder private var downloadsButton: some View {
        if !downloads.items.isEmpty { DownloadsButton() }
    }

    private var plus: some View {
        SidebarIconButton(
            symbol: "plus",
            help: "New Tab (right-click for its kind)",
            menu: AnyView(kinds),
            action: { AppActions.shared.newTab() }
        )
    }

    @ViewBuilder private var kinds: some View {
        Button("New Terminal Tab") { AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil)) }
        Button("New Web Page") { AppActions.shared.newTab(kind: PaneContentKinds.newPage) }
        Button("New Private Tab") { AppActions.shared.newTab(kind: PaneContentKinds.newPrivatePage) }
    }
}
