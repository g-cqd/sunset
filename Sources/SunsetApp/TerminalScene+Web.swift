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

    /// The window's address bar and its list, in one glass container (they render together; spacing 0: they do not blend at rest).
    var windowAddressBar: some View {
        // The list of the sidebar's field or the window bar's, as wide as the content: under the field, or over the bar at the bottom.
        let atTop = addressPlace == .sidebar || configuration.web.windowBar == .top
        return GlassEffectContainer(spacing: 0) {
            ZStack(alignment: atTop ? .top : .bottom) {
                if addressPlace == .window, let page = focusedPage {
                    WindowAddressBar(content: page, atTop: configuration.web.windowBar == .top)
                        .id(ObjectIdentifier(page))
                }
                AddressSuggestionList(typing: addressTyping, places: [.top, .bottom])
                    .padding(atTop ? .top : .bottom, addressPlace == .window ? Design.Space.m + Design.Size.bar : 0)
                    .frame(maxHeight: .infinity, alignment: atTop ? .top : .bottom)
            }
        }
    }

    /// The corners of the pane area that are corners of the window: a docked sidebar covers the corners on its side, the built-in bar those at its edge.
    var areaWindowCorners: CornerSet {
        var corners = CornerSet.all
        if configuration.sidebarDocked {
            corners.subtract(sidebarSide == .left ? [.topLeading, .bottomLeading] : [.topTrailing, .bottomTrailing])
        }
        if tabs.showsHistory {
            corners.subtract(sidebarSide == .left ? [.topTrailing, .bottomTrailing] : [.topLeading, .bottomLeading])
        }
        if presentation.showsBuiltInBar {
            corners.subtract(
                configuration.tabs.bar.position == .top
                    ? [.topLeading, .topTrailing] : [.bottomLeading, .bottomTrailing]
            )
        }
        return corners
    }

    /// The history panel on the side opposite the tabs (web step e), placed as the docked sidebar is: its margin on the window's edge and top.
    var historyPanel: some View {
        let side: Configuration.Side = sidebarSide == .left ? .right : .left
        return HistoryPanel(tabs: tabs, layout: configuration.layout)
            .padding(.top, configuration.sidebar.padding)
            .padding(side.edge, configuration.sidebar.padding)
            .frame(width: configuration.sidebar.width)
            .frame(maxHeight: .infinity)
            .transition(.move(edge: side.moveEdge).combined(with: .opacity))
    }

    /// A private window's first page (web step h): its pages share one store unless `web.privateWindowShares` says not.
    func startPrivate() {
        AppActions.shared.pendingPrivateWindow = false
        tabs.privateGroup = UUID()
        tabs.privateShares = configuration.web.privateWindowShares
        tabs.newTab(PaneContentKinds.newPage)
    }
}
