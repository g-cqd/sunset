internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// A plain setting's value: one for both schemes, or `{ "light": …, "dark": … }`. The dark one is the configuration's
    /// own; the light one is kept as JSON in `lightValues`, read again where the app is light (design 0009). A plain value
    /// keeps a light default only when it is the default (`keepsLightDefault`).
    mutating func readCodec(_ codec: SettingCodec, _ value: JSONValue) {
        guard case .object(let pair) = value, Set(pair.keys) == ["light", "dark"], let dark = pair["dark"],
            let light = pair["light"]
        else {
            codec.read(&self, value)
            let literal = codec.literal(configuration)
            let kept = Configuration.keepsLightDefault(codec.key, literal: literal)
            configuration.lightValues[codec.key] = kept ? Configuration.defaultLightValues[codec.key] : nil
            return
        }
        codec.read(&self, dark)
        var scratch = Reader(configuration: configuration, scope: scope)
        codec.read(&scratch, light)
        issues += scratch.issues
        guard scratch.issues.isEmpty else {
            configuration.lightValues[codec.key] = nil
            return
        }
        // The same value in both is one for both.
        let literal = codec.literal(scratch.configuration)
        configuration.lightValues[codec.key] = literal == codec.literal(configuration) ? nil : literal
    }
}
