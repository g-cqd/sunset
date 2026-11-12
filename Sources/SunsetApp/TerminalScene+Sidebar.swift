import SunsetConfig
import SunsetHost
import SunsetMetrics
import SunsetPrivate
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The parts of the terminal window that belong to the sidebar: the window's corner radius, the traffic lights' place, the resize strip, the floating panel.
extension TerminalScene {
    /// The window's corner radius, from AppKit (16 pt on macOS 27.0.1).
    var windowRadius: Double {
        window.flatMap { WindowCornerRadius.of($0) } ?? ConcentricRadius.standardWindow
    }
    var sidebarSide: Configuration.Side { configuration.sidebar.side }
    var floatsSidebar: Bool { presentation.showsSidebar && configuration.sidebar.autoHide }

    /// With the sidebar the traffic lights are part of it, in the slot at its top (`SidebarHeader`), away from the window's edge: docked they are always
    /// there; floating they come and go with the panel, which is inset by the margin.
    var lights: LightsPlacement? {
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
                width: configuration.sidebar.width,
                margin: configuration.sidebar.padding,
                tabSideInset: configuration.layout.tabSideInset
            )
            SidebarResizeHandle(width: configuration.sidebar.width, hitWidth: hit, side: sidebarSide)
                .padding(sidebarSide.edge, max(centre - hit / 2, 0))
        }
    }

    @ViewBuilder var floatingSidebar: some View {
        if floatsSidebar {
            FloatingSidebar(
                tabs: tabs,
                settings: configuration,
                windowRadius: windowRadius,
                shown: $floatingShown,
                opensAtOnce: $opensAtOnce
            )
            .transition(.opacity)
        }
    }
}
