import SunsetMetrics

/// The options of Window; the numbers of the layout that measure it are added in `SettingsSection`.
extension SettingsOption {
    /// The window's own (the owner's note n115: the title bar and its buttons are fixed: no title bar, the traffic lights
    /// with the sidebar 8 points in; the drag strip's height and haptic feedback stay).
    static let window: [Self] =
        [
            number("window.dragStrip", "Drag strip height", "move drag top", \.window.dragStrip, 0 ... 64, step: 1),
            toggle(
                "appearance.haptics",
                "Haptic feedback",
                "haptic haptics feedback trackpad force touch click tap",
                \.appearance.haptics
            )
            .noted("On a Force Touch trackpad, when a click goes through (light) or is blocked (firmer).")
        ]

    /// Spacing and corners.
    static let spacing: [Self] =
        [
            number(
                "window.padding",
                "Padding inside the terminal",
                "padding margin space edge border text inset",
                \.window.padding,
                0 ... 32,
                step: 1
            )
            .noted("Between the edge of the terminal's card and its text. Beside a docked sidebar it is at least 6 pt.")
        ]
}
