internal import AemiJSONCore

extension Configuration {
    /// As it is in the light scheme: its plain settings' light values (`lightValues`) over its own.
    public func inLight() -> Self {
        guard !lightValues.isEmpty else { return self }
        var reader = Reader(configuration: self)
        for (key, literal) in lightValues.sorted(by: { $0.key < $1.key }) {
            guard let codec = SettingCodec.byKey[key], let json = try? JSONValue(parsing: literal) else { continue }
            codec.read(&reader, json)
        }
        return reader.configuration
    }

    /// Whether the setting `key` is a plain one, which can have a value of its own in the light scheme.
    public static func hasSchemeValues(_ key: String) -> Bool {
        SettingCodec.byKey[key] != nil
    }

    /// The setting `key` as JSON in `configuration` (nil: not a plain setting).
    public static func literal(of key: String, in configuration: Self) -> String? {
        SettingCodec.byKey[key]?.literal(configuration)
    }
}
