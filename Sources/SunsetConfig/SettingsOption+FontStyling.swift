/// Additional terminal font styling options (T-7 / t182): per-style font overrides, ordered fallback families,
/// and OpenType variable-font axes.
extension SettingsOption {
    static var fontStyling: [Self] {
        [
            fontOverride("font.boldFamily", "Bold font", "font bold weight typeface style", \.font.boldFamily),
            fontOverride("font.italicFamily", "Italic font", "font italic oblique typeface style", \.font.italicFamily),
            fontOverride(
                "font.boldItalicFamily",
                "Bold italic font",
                "font bold italic typeface style",
                \.font.boldItalicFamily
            ),
            text(
                "font.fallbacks",
                "Fallback fonts",
                "font fallback cascade order emoji cjk symbols",
                \.font.fallbacks,
                prompt: "Symbols Nerd Font, PingFang SC"
            )
            .grouped("Styles and fallbacks"),
            text(
                "font.variations",
                "Variable font axes",
                "font variable axis wght wdth opsz slnt",
                \.font.variations,
                prompt: "wght=500, opsz=12"
            )
            .grouped("OpenType")
        ]
    }

    private static func fontOverride(
        _ id: String,
        _ title: String,
        _ keywords: String,
        _ path: any WritableKeyPath<Configuration, String?> & Sendable
    ) -> Self {
        Self(id, title, keywords, .optionalText(SettingsValue(path), prompt: "Automatic"))
            .grouped("Styles and fallbacks")
    }
}
