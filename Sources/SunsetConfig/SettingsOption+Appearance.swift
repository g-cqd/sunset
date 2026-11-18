/// The options of Appearance.
extension SettingsOption {
    /// The theme and the colours it sets.
    static let theme: [Self] =
        [
            Self(
                "theme",
                "Theme",
                "colors scheme file themes nord dark light",
                .optionalText(SettingsValue(\.theme), prompt: "nord")
            )
            .code()
            .noted(
                "A file `themes/<name>.json` beside the configuration file; it can set the font, colors, window, sidebar and "
                    + "appearance. Your own keys win."
            ),
            choice(
                "appearance.scheme",
                "Color scheme",
                "dark light system appearance mode lock",
                \.appearance.scheme,
                [(.dark, "Dark"), (.light, "Light"), (.system, "Follow the system")]
            )
            .noted("For the whole app. Light has its own tint; a dark terminal theme stays dark and opaque in it."),
            color("colors.foreground", "Foreground", "text color colour theme", \.colors.foreground, [229, 229, 229]),
            color("colors.background", "Background", "color colour theme", \.colors.background, [0, 0, 0]),
            custom("colors.ansi", "ANSI colors", "palette 16 red green blue terminal colors kitty", .ansiPalette)
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
                "Bars",
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
            .noted("With the window background set to Material: how much of what is behind the window shows through.")
            .grouped("Window"),
            number("window.blur", "Window blur", "radius frosted background", \.window.blur, 0 ... 100, step: 1)
                .grouped("Window"),
            number(
                "terminal.opacity",
                "Background opacity",
                "transparent alpha see through screen translucent",
                \.terminal.opacity,
                0 ... 1,
                step: 0.05,
                unit: ""
            )
            .noted(
                "How opaque the terminal screen's own background is. It only shows when the window background is not Opaque "
                    + "(the option above); the sidebar follows the window's settings."
            )
            .grouped("Terminal"),
            choice(
                "appearance.glass",
                "Glass style",
                "liquid glass regular clear",
                \.appearance.glass,
                [(.regular, "Regular"), (.clear, "Clear")]
            )
            .grouped("Bars"),
            choice(
                "appearance.barBlur",
                "Under the bars",
                "blur variable fade bar sidebar",
                \.appearance.barBlur,
                [(.variable, "Fading blur"), (.surface, "Bar surface"), (.none, "Nothing")]
            )
            .grouped("Bars")
        ]
}
