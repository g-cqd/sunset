import SunsetConfig
import SunsetHost

/// What the window needs from the configuration, worked out in one place.
extension Configuration {
    /// The sidebar lists the native tabs, so it exists only with them (the built-in tab bar excludes it, and with no tabs there is nothing to list).
    var sidebarShown: Bool { presentation.showsSidebar }

    /// Space around the terminal in points: the sidebar's 2 to 4 while it is shown, the window's own (0 by default) when it is not.
    var terminalPadding: Double { sidebarShown ? sidebar.padding : window.padding }

    /// How opaque the terminal's default background is: fully, with an opaque window, else as `window.opacity` says.
    var backgroundAlpha: UInt8 {
        window.material == .opaque ? 255 : UInt8((window.opacity * 255).rounded())
    }

    /// How the tabs are shown.
    var presentation: TabPresentation { TabPresentation.resolve(mode: tabs.mode, sidebar: sidebar.enabled) }
}
