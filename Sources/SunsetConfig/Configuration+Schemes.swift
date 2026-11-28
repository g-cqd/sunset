internal import AemiJSONCore

extension Configuration {
    /// As it is in the light scheme: each look setting's light value, macOS's where none was chosen (design 0009).
    public func inLight() -> Self {
        var reader = Reader(configuration: self)
        for key in Self.schemeKeys {
            guard let codec = SettingCodec.byKey[key],
                let literal = lightValues[key] ?? Self.nativeLiteral(of: key, light: true),
                let json = try? JSONValue(parsing: literal)
            else { continue }
            codec.read(&reader, json)
        }
        return reader.configuration
    }

    /// As it is in a scheme: the configuration's own in dark.
    public func inScheme(light: Bool) -> Self {
        light ? inLight() : self
    }

    /// Whether the look setting `key` was changed in a scheme: it is not macOS's there.
    public func changes(_ key: String, light: Bool) -> Bool {
        guard Self.isSchemeKey(key) else { return false }
        if light { return lightValues[key] != nil }
        return Self.literal(of: key, in: self) != Self.nativeLiteral(of: key, light: false)
    }

    /// The look setting `key` back to macOS's value in a scheme.
    public mutating func resetToNative(_ key: String, light: Bool) {
        if light {
            lightValues[key] = nil
            return
        }
        guard let codec = SettingCodec.byKey[key], let literal = Self.nativeLiteral(of: key, light: false),
            let json = try? JSONValue(parsing: literal)
        else { return }
        var reader = Reader(configuration: self)
        codec.read(&reader, json)
        self = reader.configuration
    }

    /// Keeps `literal` as the light value of `key`; macOS's is none.
    public mutating func setLight(_ key: String, _ literal: String?) {
        lightValues[key] = literal == Self.nativeLiteral(of: key, light: true) ? nil : literal
    }

    /// Whether the setting `key` is a look setting, which has a value per scheme.
    public static func hasSchemeValues(_ key: String) -> Bool {
        isSchemeKey(key)
    }

    /// The setting `key` as JSON in `configuration` (nil: not a plain setting).
    public static func literal(of key: String, in configuration: Self) -> String? {
        SettingCodec.byKey[key]?.literal(configuration)
    }
}
