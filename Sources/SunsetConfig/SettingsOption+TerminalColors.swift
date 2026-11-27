/// Terminal › Colors: the theme, the terminal's colors and how much of the window shows through it.
extension SettingsOption {
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
            color("colors.foreground", "Foreground", "text color colour theme", \.colors.foreground, [229, 229, 229])
                .inBothSchemes,
            color("colors.background", "Background", "color colour theme", \.colors.background, [0, 0, 0])
                .inBothSchemes,
            custom("colors.ansi", "ANSI colors", "palette 16 red green blue terminal colors kitty", .ansiPalette),
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
            .shown { $0.window.material != .opaque }
        ]
}
