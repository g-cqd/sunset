extension Configuration {
    /// The look settings' values in light where macOS's differ from its dark ones (design 0009, measured on macOS 27): the
    /// terminal's text and text background, and a palette that reads on it. A look setting not here is the same in both:
    /// its default (`Configuration()`), macOS's dark.
    public static let nativeLight: [String: String] = [
        SettingsOption.foregroundKey: ConfigurationWriter.color(Colors.lightForeground),
        SettingsOption.backgroundKey: ConfigurationWriter.color(Colors.lightBackground),
        SettingsOption.ansiKey: ConfigurationWriter.palette(Colors.lightAnsi)
    ]

    /// The look settings: a value in light and one in dark, each macOS's until changed in that scheme (design 0009).
    public static let schemeKeys: [String] = SettingsOption.all.filter(\.perScheme).map(\.id)
        .filter { SettingCodec.byKey[$0] != nil }

    /// Whether `key` is a look setting, with a value per scheme.
    public static func isSchemeKey(_ key: String) -> Bool {
        schemeKeySet.contains(key)
    }

    private static let schemeKeySet = Set(schemeKeys)

    /// macOS's value of the look setting `key` in a scheme, as JSON.
    public static func nativeLiteral(of key: String, light: Bool) -> String? {
        guard let codec = SettingCodec.byKey[key] else { return nil }
        return (light ? nativeLight[key] : nil) ?? codec.literal(Configuration())
    }
}
