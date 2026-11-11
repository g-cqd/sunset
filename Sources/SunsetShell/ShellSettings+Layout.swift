package import SwiftUI

extension ShellSettings {
    /// `layout.*`: every measure of the shell, in points unless said otherwise. The names and the defaults are the configuration file's.
    package struct Layout: Sendable, Equatable {
        package var tabSpacing = 4.0
        package var tabSideInset = 2.0
        package var tabPaddingLeading = 8.0
        package var tabPaddingTrailing = 4.0
        package var tabPaddingVertical = 3.0
        package var tabRadius = 6.0
        package var closeButtonSize = 20.0
        package var closeButtonRadius = 4.0
        /// The tab metrics of the floating panel (it can look different from the docked sidebar).
        package var floatingTabSpacing = 3.0
        package var floatingTabSideInset = 4.0
        package var floatingTabPaddingLeading = 8.0
        package var floatingTabPaddingTrailing = 4.0
        package var floatingTabPaddingVertical = 3.0
        package var floatingTabRadius = 6.0
        package var floatingCloseButtonSize = 20.0
        package var floatingCloseButtonRadius = 4.0
        /// Width of the strip that resizes the sidebar by dragging.
        package var resizeHandleWidth = 8.0
        package var lightsInset = 8.0
        package var lightsGap = 10.0
        package var floatingLightsExtra = 0.0
        package var pinButtonSize = 24.0
        package var pinButtonRadius = 5.0
        package var hairlineWidth = 0.5
        package var hairlineOpacity = 0.12
        package var revealStripWidth = 10.0
        /// The space between the panes of a split (and between them and the window's edge) when the sidebar is not docked.
        package var paneGap = 2.0
        /// The radius of a card's corners that are next to the sidebar or to another pane.
        package var innerCornerRadius = 6.0
        /// Seconds the floating sidebar stays after the pointer leaves it.
        package var hideDelay = 0.35
        /// Seconds of the one transition between states (hover, selection, pinning).
        package var animation = 0.15
        /// Corner radius of the content's card while the sidebar is docked; nil: concentric with the window's corners.
        package var terminalRadius: Double?
        /// Corner radius of the floating panel; nil: concentric with the window's corners.
        package var panelRadius: Double?

        package init() {}

        /// The layout with the tab metrics the floating panel draws with (its own `floatingTab*` and `floatingCloseButton*`) in place of the docked ones.
        package var floatingTabs: Layout {
            var copy = self
            copy.tabSpacing = floatingTabSpacing
            copy.tabSideInset = floatingTabSideInset
            copy.tabPaddingLeading = floatingTabPaddingLeading
            copy.tabPaddingTrailing = floatingTabPaddingTrailing
            copy.tabPaddingVertical = floatingTabPaddingVertical
            copy.tabRadius = floatingTabRadius
            copy.closeButtonSize = floatingCloseButtonSize
            copy.closeButtonRadius = floatingCloseButtonRadius
            return copy
        }

        /// The one transition between states (hover, selection, pinning): eased, as long as `animation` says.
        package var smooth: Animation { .easeInOut(duration: animation) }
    }
}
