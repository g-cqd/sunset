/// Every key the file can set, as dotted paths: what the reader accepts and the writer writes (a test keeps the three together). The keys of one section are
/// together, in the order the written file shows them: the writer opens a section once.
public enum ConfigurationKeys {
    public static let all: [String] = [
        "theme",
        "font.family", "font.size", "font.ligatures", "font.features",
        "colors.foreground", "colors.background", "colors.cursor", "colors.ansi",
        "window.decorations", "window.trafficLights.x", "window.trafficLights.y", "window.trafficLights.side",
        "window.dragStrip", "window.padding",
        "window.material", "window.blur", "terminal.opacity",
        "sidebar.enabled", "sidebar.width", "sidebar.padding", "sidebar.autoHide", "sidebar.side",

        "layout.tabSpacing", "layout.tabSideInset", "layout.tabPaddingLeading", "layout.tabPaddingTrailing",
        "layout.tabPaddingVertical", "layout.tabRadius", "layout.closeButtonSize", "layout.closeButtonRadius",
        "layout.floatingTabSpacing", "layout.floatingTabSideInset", "layout.floatingTabPaddingLeading",
        "layout.floatingTabPaddingTrailing", "layout.floatingTabPaddingVertical", "layout.floatingTabRadius",
        "layout.floatingCloseButtonSize", "layout.floatingCloseButtonRadius", "layout.resizeHandleWidth",
        "layout.lightsInset", "layout.lightsGap", "layout.floatingLightsExtra", "layout.pinButtonSize",
        "layout.pinButtonRadius", "layout.hairlineWidth", "layout.hairlineOpacity", "layout.revealStripWidth",
        "layout.hideDelay", "layout.animation", "layout.terminalRadius", "layout.panelRadius",
        "appearance.scheme", "appearance.glass", "appearance.tint.color", "appearance.tint.alpha",
        "tabs.mode", "tabs.bar.position", "tabs.bar.title", "tabs.bar.directory", "tabs.bar.progress",
        "scroll.trackpad", "scroll.wheel", "scroll.inertia",
        "scrollback.lines", "cursor.blinkTimeout", "renderer",
        "keyboard.optionAsMeta"
    ]
}
