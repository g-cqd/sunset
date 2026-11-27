internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// A plain setting's value: one for both schemes, or `{ "light": …, "dark": … }`. The dark one is the configuration's
    /// own; the light one is kept as JSON in `lightValues`, read again where the app is light (design 0009).
    mutating func readCodec(_ codec: SettingCodec, _ value: JSONValue) {
        guard case .object(let pair) = value, Set(pair.keys) == ["light", "dark"], let dark = pair["dark"],
            let light = pair["light"]
        else {
            configuration.lightValues[codec.key] = nil
            return codec.read(&self, value)
        }
        codec.read(&self, dark)
        var scratch = Reader(configuration: configuration, scope: scope)
        codec.read(&scratch, light)
        issues += scratch.issues
        guard scratch.issues.isEmpty else { return }
        configuration.lightValues[codec.key] = codec.literal(scratch.configuration)
    }
}
