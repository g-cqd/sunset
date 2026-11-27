/// The options of Appearance.
extension SettingsOption {
    /// Sunset's scheme and its icon.
    static let appearance: [Self] =
        [
            choice(
                "appearance.scheme",
                "Color scheme",
                "dark light system appearance mode lock",
                \.appearance.scheme,
                [(.dark, "Dark"), (.light, "Light"), (.system, "Follow the system")]
            )
            .noted("For the whole app. Light has its own tint; a dark terminal theme stays dark and opaque in it."),
            choice(
                "appearance.icon",
                "App icon",
                "icon dock app sky auto time day sunset twilight dawn dusk alternate",
                \.appearance.icon,
                [(.auto, "Auto"), (.dawn, "Dawn"), (.sunset, "Sunset"), (.twilight, "Twilight"), (.dusk, "Dusk")]
            )
            .noted(
                "Auto follows the time of day while Sunset runs; Finder and a Dock kept icon show Sunset's own when it is not running."
            )
        ]

    /// The accent and the tint.
    static let tint: [Self] =
        [
            choice(
                "appearance.accent",
                "Accent",
                "colour color highlight selection sunset neutral system site website theme icon",
                \.appearance.accent,
                [(.system, "System"), (.sunset, "Sunset"), (.neutral, "Neutral"), (.site, "From the website")]
            )
            .noted("From the website: the color the page declares, else its icon's; the system's for anything else."),
            color("appearance.tint.color", "Tint", "colour color overlay glass", \.appearance.tintColor, [48, 96, 255]),
            number(
                "appearance.tint.alpha",
                "Tint strength",
                "alpha opacity overlay",
                \.appearance.tintAlpha,
                0 ... 1,
                step: 0.05,
                unit: ""
            ),
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
            choice(
                "appearance.barTint",
                "Bar appearance",
                "tint dark light bar address find",
                \.appearance.barTint,
                [(.scheme, "Follow the color scheme"), (.dark, "Dark"), (.light, "Light")]
            )
        ]

    /// What the window and its surfaces are made of.
    static let materials: [Self] =
        [
            choice(
                "window.material",
                "Window background",
                "material glass transparent opaque blur vibrancy",
                \.window.material,
                [(.opaque, "Opaque"), (.material, "Material"), (.glass, "Glass"), (.fill, "Color fill")],
                label: "Window and sidebar background"
            )
            .formerly(["transparent": "fill"])
            .grouped("Window"),
            choice(
                "window.materialThickness",
                "Material thickness",
                "material thickness thin thick ultrathin ultrathick frosted opaque",
                \.window.materialThickness,
                [
                    (.ultraThin, "Ultra thin"), (.thin, "Thin"), (.regular, "Regular"), (.thick, "Thick"),
                    (.ultraThick, "Ultra thick")
                ]
            )
            .noted("How much of what is behind the window shows through.")
            .grouped("Window")
            .shown { $0.window.material == .material },
            choice(
                "appearance.glass",
                "Glass style",
                "liquid glass regular clear",
                \.appearance.glass,
                [(.regular, "Regular"), (.clear, "Clear")]
            )
            .grouped("Window")
            .shown { $0.window.material == .glass },
            number("window.blur", "Window blur", "radius frosted background", \.window.blur, 0 ... 100, step: 1)
                .grouped("Window")
                .shown { $0.window.material == .material || $0.window.material == .glass },
            choice(
                "appearance.ends",
                "Ends of lists and titles",
                "fade fading alpha ends cut list title edge",
                \.appearance.ends,
                [(.fade, "Fade out"), (.cut, "Cut")]
            )
            .grouped("Lists and titles")
            .noted("Where a list scrolls under a title or a bar, and where a title is too long."),
            choice(
                "appearance.barBlur",
                "Under the bars",
                "blur variable fade bar sidebar",
                \.appearance.barBlur,
                [(.variable, "Fading blur"), (.surface, "Bar surface"), (.none, "Nothing")]
            )
            .grouped("Bar appearance")
        ]
}
