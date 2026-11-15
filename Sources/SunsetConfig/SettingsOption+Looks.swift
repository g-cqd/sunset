/// The options of the Appearance and Window panes.
extension SettingsOption {
    static let appearance = pane(
        "appearance",
        [
            Self(
                "theme",
                "Theme",
                "colors scheme file themes nord dark light",
                .optionalText(SettingsValue(\.theme), prompt: "nord")
            )
            .noted(
                "A file themes/<name>.json beside the configuration file; it can set the font, colours, window, sidebar and "
                    + "appearance. Your own keys win."
            ),
            choice(
                "window.material",
                "Window background",
                "material glass transparent opaque blur vibrancy",
                \.window.material,
                [(.opaque, "Opaque"), (.material, "Material"), (.glass, "Glass"), (.fill, "Colour fill")],
                label: "Window and sidebar background"
            ),
            number("window.blur", "Window blur", "radius frosted background", \.window.blur, 0 ... 100, step: 1),
            number("window.padding", "Padding", "margin space edge border", \.window.padding, 0 ... 32, step: 1),
            choice(
                "appearance.scheme",
                "Color scheme",
                "dark light system appearance mode lock",
                \.appearance.scheme,
                [(.dark, "Dark (locked)"), (.light, "Light"), (.system, "Follow the system")]
            )
            .noted("For the whole app. Light has its own tint; a dark terminal theme stays dark and opaque in it."),
            choice(
                "appearance.glass",
                "Glass style",
                "liquid glass regular clear",
                \.appearance.glass,
                [(.regular, "Regular"), (.clear, "Clear")]
            ),
            choice(
                "appearance.accent",
                "Accent",
                "colour color highlight selection sunset neutral system",
                \.appearance.accent,
                [(.system, "The system's"), (.sunset, "Sunset"), (.neutral, "Neutral")]
            ),
            choice(
                "appearance.barTint",
                "Bars",
                "tint dark light bar address find",
                \.appearance.barTint,
                [(.scheme, "Follow the color scheme"), (.dark, "Dark"), (.light, "Light")]
            ),
            choice(
                "appearance.barBlur",
                "Under the bars",
                "blur variable fade bar sidebar",
                \.appearance.barBlur,
                [(.variable, "Fading blur"), (.surface, "The bar's surface"), (.none, "Nothing")]
            ),
            color("appearance.tint.color", "Tint", "colour color overlay glass", \.appearance.tintColor, [48, 96, 255]),
            color(
                "appearance.tint.light",
                "Tint in the light scheme",
                "colour color overlay glass light",
                \.appearance.lightTintColor,
                [255, 255, 255]
            ),
            number(
                "appearance.tint.lightAlpha",
                "Tint strength in the light scheme",
                "alpha opacity light",
                \.appearance.lightTintAlpha,
                0 ... 1,
                step: 0.05,
                unit: ""
            ),
            number(
                "appearance.tint.alpha",
                "Tint strength",
                "alpha opacity overlay",
                \.appearance.tintAlpha,
                0 ... 1,
                step: 0.05,
                unit: ""
            )
        ]
    )

    static let window = pane(
        "window",
        [
            choice(
                "window.decorations",
                "Title bar",
                "decorations chrome frame native",
                \.window.decorations,
                [(.none, "None (content under the title bar)"), (.native, "System")]
            ),
            number("window.dragStrip", "Drag strip", "move drag top", \.window.dragStrip, 0 ... 64, step: 1),
            choice(
                "window.trafficLights.side",
                "Traffic lights, side",
                "close mirror left right buttons",
                \.window.lightsSide,
                [(.sidebar, "With the sidebar"), (.left, "Left"), (.right, "Right (mirrored)")]
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
            )
        ]
    )
}
