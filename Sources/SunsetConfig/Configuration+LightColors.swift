extension Configuration {
    /// The light values settings have until the file says otherwise (design 0009): the terminal's light colours.
    public static let defaultLightValues: [String: String] = [
        SettingsOption.foregroundKey: ConfigurationWriter.color(Colors.lightForeground),
        SettingsOption.backgroundKey: ConfigurationWriter.color(Colors.lightBackground),
        SettingsOption.ansiKey: ConfigurationWriter.palette(Colors.lightAnsi)
    ]

    /// Whether a plain value read for `key` keeps its light default: it is the default one, which a file written by Sunset
    /// holds when it was never chosen (the writer writes every key). A value chosen is the same in both schemes.
    static func keepsLightDefault(_ key: String, literal: String) -> Bool {
        guard defaultLightValues[key] != nil, let codec = SettingCodec.byKey[key] else { return false }
        return literal == codec.literal(Configuration())
    }
}
