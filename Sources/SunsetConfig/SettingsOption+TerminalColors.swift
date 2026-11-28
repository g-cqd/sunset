/// Look and feel › Terminal colors: the theme, the terminal's colors and how much of the window shows through it.
extension SettingsOption {
    /// The keys of the terminal's colours, whose light values are not their dark ones by default (`nativeLight`).
    static let foregroundKey = "colors.foreground"
    static let backgroundKey = "colors.background"
    static let ansiKey = "colors.ansi"

    static let terminalColors: [Self] =
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
            color(foregroundKey, "Foreground", "text color colour theme", \.colors.foreground, [229, 229, 229])
                .inBothSchemes,
            color(backgroundKey, "Background", "color colour theme", \.colors.background, [0, 0, 0])
                .inBothSchemes,
            color("colors.cursor", "Cursor color", "caret color colour", \.colors.cursor, [229, 229, 229])
                .inBothSchemes,
            custom(ansiKey, "ANSI colors", "palette 16 red green blue terminal colors kitty", .ansiPalette)
                .inBothSchemes,
            number(
                "terminal.opacity",
                "Background opacity",
                "transparent alpha see through screen translucent",
                \.terminal.opacity,
                0 ... 1,
                step: 0.05,
                unit: ""
            )
            .inBothSchemes
            .noted("How opaque the terminal screen's own background is; the sidebar follows the window's settings.")
        ]
}
