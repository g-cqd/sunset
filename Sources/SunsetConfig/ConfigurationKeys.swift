/// Every key the file can set, as dotted paths: what the reader accepts and the writer writes (a test keeps the three together).
public enum ConfigurationKeys {
    public static let all: [String] = [
        "font.family", "font.size", "font.ligatures", "font.features",
        "colors.foreground", "colors.background", "colors.cursor",
        "window.decorations", "window.trafficLights.x", "window.trafficLights.y", "window.dragStrip",
        "scroll.trackpad", "scroll.wheel",
        "scrollback.lines", "cursor.blinkTimeout", "renderer",
        "keyboard.optionAsMeta"
    ]
}
