import SunsetAppCore
import SunsetConfig
import SunsetShell

extension Configuration {
    /// What the panes that are not terminals are drawn on: the terminal's default background, as opaque as the terminal's.
    var paneBackdrop: PaneBackdrop {
        PaneBackdrop(rgb: colors.background, terminalAlpha: backgroundAlpha)
    }
}
