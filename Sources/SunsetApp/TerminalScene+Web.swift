import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Where the address of the focused page is typed (web step b): the field at the top of the docked sidebar, the window bar (also while the sidebar is
/// not docked), or a row in each page. Nothing while a terminal has the keyboard.
extension TerminalScene {
    var focusedPage: WebContent? { tabs.selectedContent as? WebContent }

    /// The placement the settings ask for; the sidebar's field needs a sidebar beside the content, else the window bar stands in.
    var addressPlace: Configuration.Web.AddressPlace {
        let wanted = configuration.web.address
        return wanted == .sidebar && !configuration.sidebarDocked ? .window : wanted
    }

    var sidebarAddress: AnyView? {
        guard addressPlace == .sidebar, let page = focusedPage else { return nil }
        return AnyView(AddressField(content: page).id(ObjectIdentifier(page)))
    }

    @ViewBuilder var windowAddressBar: some View {
        if addressPlace == .window, let page = focusedPage {
            WindowAddressBar(content: page, atTop: configuration.web.windowBar == .top).id(ObjectIdentifier(page))
        }
    }

    /// The corners of the pane area that are corners of the window: a docked sidebar covers the corners on its side, the built-in bar those at its edge.
    var areaWindowCorners: CornerSet {
        var corners = CornerSet.all
        if configuration.sidebarDocked {
            corners.subtract(sidebarSide == .left ? [.topLeading, .bottomLeading] : [.topTrailing, .bottomTrailing])
        }
        if presentation.showsBuiltInBar {
            corners.subtract(
                configuration.tabs.bar.position == .top
                    ? [.topLeading, .topTrailing] : [.bottomLeading, .bottomTrailing]
            )
        }
        return corners
    }
}
