import SunsetMetrics

/// The options of Window; the numbers of the layout that measure it are added in `SettingsSection`.
extension SettingsOption {
    /// The title bar and the window's buttons.
    static let titleBar: [Self] =
        [
            choice(
                "window.decorations",
                "Title bar",
                "decorations chrome frame native",
                \.window.decorations,
                [(.none, "None"), (.native, "System")]
            )
            .noted("With none, the content reaches under the title bar."),
            number("window.dragStrip", "Drag strip height", "move drag top", \.window.dragStrip, 0 ... 64, step: 1),
            choice(
                "window.trafficLights.side",
                "Traffic light side",
                "close mirror left right buttons",
                \.window.lightsSide,
                [(.sidebar, "With the sidebar"), (.left, "Left"), (.right, "Right, mirrored")]
            ),
            number(
                "window.trafficLights.x",
                "Traffic light inset from the side",
                "close minimize zoom buttons position",
                \.window.trafficLightsX,
                0 ... 400,
                step: 1
            ),
            number(
                "window.trafficLights.y",
                "Traffic light inset from the top",
                "close minimize zoom buttons position",
                \.window.trafficLightsY,
                0 ... 400,
                step: 1
            ),
            toggle(
                "appearance.haptics",
                "Haptic feedback",
                "haptic haptics feedback trackpad force touch click tap",
                \.appearance.haptics
            )
            .grouped("Buttons")
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
