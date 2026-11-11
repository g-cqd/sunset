package import SunsetConfig
package import SunsetShell

extension ShellSettings.Layout {
    /// The shell's measures as `layout.*` of the configuration file says them, each under the same name.
    package init(_ layout: Configuration.Layout) {
        self.init()
        tabSpacing = layout.tabSpacing
        tabSideInset = layout.tabSideInset
        tabPaddingLeading = layout.tabPaddingLeading
        tabPaddingTrailing = layout.tabPaddingTrailing
        tabPaddingVertical = layout.tabPaddingVertical
        tabRadius = layout.tabRadius
        closeButtonSize = layout.closeButtonSize
        closeButtonRadius = layout.closeButtonRadius
        floatingTabSpacing = layout.floatingTabSpacing
        floatingTabSideInset = layout.floatingTabSideInset
        floatingTabPaddingLeading = layout.floatingTabPaddingLeading
        floatingTabPaddingTrailing = layout.floatingTabPaddingTrailing
        floatingTabPaddingVertical = layout.floatingTabPaddingVertical
        floatingTabRadius = layout.floatingTabRadius
        floatingCloseButtonSize = layout.floatingCloseButtonSize
        floatingCloseButtonRadius = layout.floatingCloseButtonRadius
        resizeHandleWidth = layout.resizeHandleWidth
        lightsInset = layout.lightsInset
        lightsGap = layout.lightsGap
        floatingLightsExtra = layout.floatingLightsExtra
        pinButtonSize = layout.pinButtonSize
        pinButtonRadius = layout.pinButtonRadius
        hairlineWidth = layout.hairlineWidth
        hairlineOpacity = layout.hairlineOpacity
        revealStripWidth = layout.revealStripWidth
        paneGap = layout.paneGap
        innerCornerRadius = layout.innerCornerRadius
        hideDelay = layout.hideDelay
        animation = layout.animation
        terminalRadius = layout.terminalRadius
        panelRadius = layout.panelRadius
    }
}
