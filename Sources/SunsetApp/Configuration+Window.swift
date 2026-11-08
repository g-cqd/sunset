import SunsetConfig
import SunsetHost

/// What the window needs from the configuration, worked out in one place.
extension Configuration {
    /// The sidebar lists the native tabs, so it exists only with them (the built-in tab bar excludes it, and with no tabs there is nothing to list).
    var sidebarShown: Bool { presentation.showsSidebar }

    /// The sidebar stays beside the terminal (and the terminal is a card); with `autoHide` it floats over it on hover instead.
    var sidebarDocked: Bool { sidebarShown && !sidebar.autoHide }

    /// Space between the grid and the terminal's own edge in points: the terminal's background fills it, with or without the sidebar (the sidebar's
    /// `padding` is outside the terminal, in the window's colour: `TerminalCard`). In the card at least 6 pt, so that text is not cut by its rounded corners.
    var terminalPadding: Double { sidebarDocked ? max(window.padding, 6) : window.padding }

    /// How opaque the terminal's default background is: fully, with an opaque window, else as `window.opacity` says.
    var backgroundAlpha: UInt8 {
        window.material == .opaque ? 255 : UInt8((window.opacity * 255).rounded())
    }

    /// How the tabs are shown.
    var presentation: TabPresentation { TabPresentation.resolve(mode: tabs.mode, sidebar: sidebar.enabled) }
}
