import SunsetAppCore
import SunsetConfig
import SunsetHost
import SunsetMetrics
import SunsetPrivate
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// The parts of the terminal window that belong to the sidebar: the window's corner radius, the traffic lights' place, the resize strip, the floating panel.
extension TerminalScene {
    /// The window's corner radius, from AppKit (16 pt on macOS 27.0.1).
    var windowRadius: Double {
        window.flatMap { WindowCornerRadius.of($0) } ?? ConcentricRadius.standardWindow
    }
    var sidebarSide: Configuration.Side {
        configuration.sidebar.side
    }
    var floatsSidebar: Bool {
        presentation.showsSidebar && configuration.sidebar.autoHide
    }

    /// With the sidebar the traffic lights are part of it, in the slot at its top (`SidebarHeader`), away from the window's edge: docked they are always
    /// there; floating they come and go with the panel, which is inset by the margin.
    var lights: LightsPlacement? {
        if addressInTabBar, configuration.tabs.bar.position == .top {
            // Centred on the tab bar's row of capsules (owner, 2026-11-13).
            return LightsPlacement(
                x: Design.TabCapsules.lightsX,
                y: Design.TabCapsules.lightsCenter,
                visible: true,
                centred: true
            )
        }
        guard presentation.showsSidebar else { return nil }
        let margin = configuration.sidebar.padding
        let origin = SidebarHeader(
            layout: ShellSettings.Layout(configuration.layout),
            margin: margin,
            floating: !configuration.sidebarDocked
        )
        .lightsOrigin
        return LightsPlacement(
            x: origin,
            y: origin,
            visible: configuration.sidebarDocked || floatingShown,
            side: configuration.window.lightsSide.resolved(sidebar: sidebarSide)
        )
    }

    /// From the window's leading edge to the tab bar's first item, past the window's buttons.
    var tabBarLightsClearance: Double {
        addressInTabBar ? Design.TabCapsules.lightsClearance - Design.TabCapsules.inset : Design.System.lightsClearance
    }

    /// The docked sidebar's resize strip, over the terminal's card too, centred in the gap between the tabs and the card (`SidebarHandle`).
    @ViewBuilder var resizeHandle: some View {
        if configuration.sidebarDocked {
            let hit = SidebarHandle.hitWidth(
                docked: true,
                wanted: configuration.layout.resizeHandleWidth,
                tabSideInset: configuration.layout.tabSideInset
            )
            let centre = SidebarHandle.center(
                docked: true,
                width: configuration.sidebar.width + libraryWidth,
                margin: configuration.sidebar.padding,
                tabSideInset: configuration.layout.tabSideInset
            )
            let start = max(centre - hit / 2, 0)
            SidebarResizeHandle(width: configuration.sidebar.width, hitWidth: hit, side: sidebarSide)
                .padding(sidebarSide.edge, start)
        }
    }

    @ViewBuilder var floatingSidebar: some View {
        if floatsSidebar {
            FloatingSidebar(
                tabs: tabs,
                settings: configuration,
                windowRadius: windowRadius,
                shown: $floatingShown,
                opensAtOnce: $opensAtOnce,
                accessory: sidebarAddress,
                held: holdsFloatingSidebar
            )
            .transition(.opacity)
        }
    }

    /// The floating sidebar's field is typed in as the docked one's is: out while the command bar is open in it, or while
    /// it holds the page's address and that is asked for (Open Address, a new page) or typed in.
    var holdsFloatingSidebar: Bool {
        if tabs.bar?.inSidebar == true { return true }
        guard addressPlace == .sidebar, let page = focusedPage else { return false }
        return page.wantsAddress || addressTyping.page === page
    }

    /// The docked sidebar's place in the row: it is drawn under the row (`body`), this keeps its width.
    var sidebarSlot: some View {
        Color.clear.frame(width: configuration.sidebar.width + libraryWidth).frame(maxHeight: .infinity)
    }

    /// How much wider the docked sidebar is while the Library is open: its rail.
    var libraryWidth: Double {
        LibrarySidebar.extraWidth(tabs, ShellSettings(configuration), floating: false)
    }

    /// The sidebar beside the terminal, on the side `sidebar.side` says: the margin is on the window's edge. Any empty area in it drags the window.
    var dockedSidebar: some View {
        AppSidebar(
            tabs: tabs,
            configuration: configuration,
            windowRadius: windowRadius,
            accessory: sidebarAddress,
            notices: AnyView(SidebarNotices(tabs: tabs, layout: configuration.layout))
        )
        .padding(.top, configuration.sidebar.padding)
        .padding(sidebarSide.edge, configuration.sidebar.padding)
        .frame(width: configuration.sidebar.width + libraryWidth, alignment: sidebarSide.alignment)
        .frame(maxHeight: .infinity)
        .background { windowDragSurface }
        .transition(.move(edge: sidebarSide.moveEdge).combined(with: .opacity))
    }
}
