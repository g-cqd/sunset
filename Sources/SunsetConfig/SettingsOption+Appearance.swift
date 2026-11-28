/// The options of Appearance.
extension SettingsOption {
    /// Keys the reader also names: the tint's, which former keys give light values (`Reader.finish`), the window's
    /// background, of which `opaque` was a value, and the setting `web.pageScheme` became.
    static let tintColorKey = "appearance.tint.color"
    static let tintAlphaKey = "appearance.tint.alpha"
    static let materialKey = "window.material"
    static let contentFollowsKey = "appearance.contentFollows"

    /// Sunset's scheme and its icon.
    static let appearance: [Self] =
        [
            choice(
                "appearance.scheme",
                "Color scheme",
                "dark light system appearance mode lock",
                \.appearance.scheme,
                [(.system, "Follow the system"), (.dark, "Dark"), (.light, "Light")]
            )
            .noted("For the whole app."),
            toggle(
                contentFollowsKey,
                "Content follows",
                "pages web documents dark light mode scheme appearance sites",
                \.appearance.contentFollows,
                label: "Pages and documents use this scheme too"
            )
            .shown { $0.appearance.scheme != .system }
            .noted("Off, they follow the system's. A site with no dark mode of its own is shown as it is."),
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
            .inBothSchemes
            .noted("From the website: the color the page declares, else its icon's; the system's for anything else."),
            color(tintColorKey, "Tint", "colour color overlay glass fill", \.appearance.tintColor, [48, 96, 255])
                .inBothSchemes
                .noted("Over the window's background; with Color, the background itself."),
            strength(tintAlphaKey, "Tint strength", \.appearance.tintAlpha).inBothSchemes,
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
                materialKey,
                "Window background",
                "material glass transparent opaque blur vibrancy",
                \.window.material,
                [(.color, "Color"), (.material, "Material"), (.glass, "Glass")],
                label: "Window and sidebar background"
            )
            .inBothSchemes
            .noted(
                "Color is the tint at its strength (the window's own color with no tint); the others are tinted by it."
            )
            .formerly(["transparent": "color", "fill": "color", "opaque": "color"])
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
            .inBothSchemes
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
            .inBothSchemes
            .grouped("Window")
            .shown { $0.window.material == .glass },
            number("window.blur", "Window blur", "radius frosted background", \.window.blur, 0 ... 100, step: 1)
                .inBothSchemes
                .noted("A blur of its own of what is behind the window, over any background.")
                .grouped("Window"),
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

    /// A tint's strength: 0 to 1 by twentieths.
    private static func strength(_ id: String, _ title: String, _ path: Path<Double>) -> Self {
        number(id, title, "alpha opacity overlay", path, 0 ... 1, step: 0.05, unit: "")
    }
}
