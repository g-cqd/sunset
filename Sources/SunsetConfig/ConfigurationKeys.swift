/// Every key the file can set, as dotted paths: what the reader accepts and the writer writes (a test keeps the three together). The keys of one section are
/// together, in the order the written file shows them: the writer opens a section once.
public enum ConfigurationKeys {
    public static let all: [String] = [
        "theme",
        "font.family", "font.size", "font.ligatures", "font.features",
        "colors.foreground", "colors.background", "colors.cursor",
        "window.decorations", "window.trafficLights.x", "window.trafficLights.y", "window.dragStrip", "window.padding",
        "window.material", "window.opacity", "window.blur",
        "sidebar.enabled", "sidebar.width", "sidebar.padding", "sidebar.material", "sidebar.blur",
        "appearance.glass", "appearance.tint.color", "appearance.tint.alpha",
        "tabs.mode", "tabs.bar.position", "tabs.bar.title", "tabs.bar.directory", "tabs.bar.progress",
        "scroll.trackpad", "scroll.wheel",
        "scrollback.lines", "cursor.blinkTimeout", "renderer",
        "keyboard.optionAsMeta"
    ]
}
