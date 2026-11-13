import SunsetConfig
import SunsetHost
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetShellBridge
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

    /// The built-in tab bar holds the address (t223): the selected tab is the field, back and forward after the window's buttons;
    /// the window bar does not come out.
    var addressInTabBar: Bool { presentation.showsBuiltInBar && addressPlace == .window }

    private var tabBarAtTop: Bool { configuration.tabs.bar.position == .top }

    var tabBarNavigation: AnyView? {
        guard addressInTabBar, let page = focusedPage else { return nil }
        return AnyView(PageNavigation(content: page, atTop: tabBarAtTop, flat: true))
    }

    var tabBarAddress: AnyView? {
        guard addressInTabBar, let page = focusedPage else { return nil }
        return AnyView(
            AddressField(content: page, place: tabBarAtTop ? .top : .bottom, reload: true)
                .environment(\.controlRadius, Design.TabCapsules.radius)
                .environment(\.controlHeight, Design.TabCapsules.height)
                .environment(\.controlPadding, Design.BarGroup.fieldPadding)
                .id(ObjectIdentifier(page))
        )
    }

    var sidebarAddress: AnyView? {
        guard addressPlace == .sidebar, let page = focusedPage else { return nil }
        return AnyView(AddressField(content: page).id(ObjectIdentifier(page)))
    }

    /// The window's address bar and its list, in one glass container (they render together; spacing 0: they do not blend at rest).
    func windowAddressBar(card: PaneCardShape?) -> some View {
        // The list of the sidebar's field or the window bar's, as wide as the content: under the field, or over the bar at the bottom.
        let atTop =
            addressInTabBar ? tabBarAtTop : addressPlace == .sidebar || configuration.web.windowBar == .top
        return GlassEffectContainer(spacing: 0) {
            ZStack(alignment: atTop ? .top : .bottom) {
                if addressPlace == .window, !addressInTabBar, let page = focusedPage {
                    // In a split with `web.splitBar` margin, across the panes in the margin it opens, over no page: no blur.
                    WindowAddressBar(
                        content: page,
                        atTop: configuration.web.windowBar == .top,
                        card: barInMargin ? nil : card,
                        inset: barInMargin ? splitGap : Design.Space.m,
                        hostsFind: hostsFind
                    ) { out in barOut = out }
                    .id(ObjectIdentifier(page))
                    .environment(\.barBlur, barInMargin ? .none : configuredBarBlur)
                }
                AddressSuggestionList(typing: addressTyping, places: [.top, .bottom])
                    .padding(
                        atTop ? .top : .bottom,
                        addressPlace == .window && !addressInTabBar ? Design.Space.m + Design.Size.bar : 0
                    )
                    .frame(maxHeight: .infinity, alignment: atTop ? .top : .bottom)
            }
        }
    }

    /// The split's window bar goes in a margin above the panes (`web.splitBar`; at the top edge only).
    var barInMargin: Bool {
        addressPlace == .window && configuration.web.splitBar == .margin && configuration.web.windowBar == .top
            && tabs.shownItem?.isSplit == true
    }

    /// The margin it opens while it is out: the bar and the split's gap under it (the same gap is above it, where the panes' tops were).
    var splitBarInset: Double { barInMargin && barOut ? Design.Size.bar + splitGap : 0 }

    /// The space between a split's cards, and between them and the window's edge (as `PaneArea` lays them out).
    var splitGap: Double { configuration.sidebarDocked ? configuration.sidebar.padding : configuration.layout.paneGap }

    /// The window bar shows the focused page's find bar in its row: at the top, over the focused pane (in the split's margin the
    /// panes have moved down and the find bar stays in its own).
    var hostsFind: Bool {
        addressPlace == .window && configuration.web.windowBar == .top && !barInMargin && !addressInTabBar
    }

    var configuredBarBlur: BarBlurChoice {
        BarBlurChoice(rawValue: configuration.appearance.barBlur.rawValue) ?? .variable
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
        return HistoryPanel(
            tabs: tabs,
            layout: ShellSettings(configuration).layout,
            margin: configuration.sidebar.padding
        )
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
