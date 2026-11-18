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
            number("window.dragStrip", "Drag strip", "move drag top", \.window.dragStrip, 0 ... 64, step: 1),
            choice(
                "window.trafficLights.side",
                "Traffic light side",
                "close mirror left right buttons",
                \.window.lightsSide,
                [(.sidebar, "With the sidebar"), (.left, "Left"), (.right, "Right, mirrored")]
            ),
            number(
                "window.trafficLights.x",
                "Traffic lights, from their edge",
                "close minimize zoom buttons position",
                \.window.trafficLightsX,
                0 ... 400,
                step: 1
            ),
            number(
                "window.trafficLights.y",
                "Traffic lights, from the top",
                "close minimize zoom buttons position",
                \.window.trafficLightsY,
                0 ... 400,
                step: 1
            ),
            toggle(
                "appearance.haptics",
                "Tap the trackpad when a click goes through or is blocked",
                "haptic haptics feedback trackpad force touch click tap",
                \.appearance.haptics
            )
            .grouped("Buttons")
            .noted("On a Force Touch trackpad: a light tap when it went through, a firmer one when it was blocked.")
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
            .noted("Between the edge of the terminal's card and its text. Beside a docked sidebar it is at least 6 pt."),
            number(
                "sidebar.padding",
                "Margin around the terminal's card",
                "padding margin gap space window edge",
                \.sidebar.padding,
                0 ... 16,
                step: 1
            )
            .noted("Between the window's edge, the sidebar and the card, while the sidebar is shown."),
            Self(
                "layout.terminalRadius",
                "Terminal card corner radius",
                "rounding card layout window",
                .radius(SettingsValue(\.layout.terminalRadius))
            )
            .further
        ]
}
