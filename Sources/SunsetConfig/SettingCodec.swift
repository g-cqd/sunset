internal import AemiJSONCore

/// How one key of the file is read and written, from the control that shows it: a setting with a plain value (a switch, a number in a range, a choice) is declared
/// once, in its `SettingsOption`, and the reader, the writer and the list of keys take it from there. What is not a plain value is read and written by hand: texts
/// (each with its own rules: empty for unset, an address checked), colours that may be unset, lists, themes, keys kept for old files.
struct SettingCodec: Sendable {
    let key: String
    /// Reads `value` into the configuration, or says what is wrong with it.
    let read: @Sendable (inout Reader, JSONValue) -> Void
    /// The value as a JSON literal.
    let literal: @Sendable (Configuration) -> String

    /// The codecs of every option whose control holds a plain value made from a key path, by key.
    static let byKey: [String: Self] = {
        var codecs: [String: Self] = [:]
        let handWritten = Set(ConfigurationKeys.byHand)
        for option in SettingsOption.all where option.keys == [option.id] && !handWritten.contains(option.id) {
            if let codec = codec(option.id, option.control, formerly: option.formerly) {
                codecs[option.id] = codec
            }
        }
        return codecs
    }()

    /// The codecs' keys in the order their options are declared.
    static let ordered: [String] = SettingsOption.all.map(\.id).filter { byKey[$0] != nil }

    private static func codec(_ key: String, _ control: SettingsControl, formerly: [String: String]) -> Self? {
        switch control {
            case .toggle(let value, _) where value.isDirect:
                return scalar(key, value, parse: { $0.bool(key, $1) }, format: { String($0) })
            case .text(let value, _) where value.isDirect:
                return scalar(key, value, parse: { $0.string(key, $1) }, format: ConfigurationWriter.string)
            case .number(let value, let range, _, _, _) where value.isDirect:
                return scalar(
                    key,
                    value,
                    parse: { $0.number(key, $1, range: range) },
                    format: ConfigurationWriter.number
                )
            case .color(let value, _) where value.isDirect:
                // null is "not set": the terminal's own colour.
                return Self(
                    key: key,
                    read: { reader, json in
                        if case .null = json { return value.set(&reader.configuration, nil) }
                        if let bytes = reader.color(key, json) { value.set(&reader.configuration, bytes) }
                    },
                    literal: { ConfigurationWriter.color(value.get($0)) }
                )
            case .choice(let choice, _):
                return Self(
                    key: key,
                    read: { reader, json in
                        guard case .string(let written) = json, case let raw = formerly[written] ?? written,
                            choice.accepts(raw)
                        else {
                            let names = choice.items.map(\.value).joined(separator: ", ")
                            reader.issue(key, "expected one of \(names)")
                            return
                        }
                        choice.set(&reader.configuration, raw)
                    },
                    literal: { ConfigurationWriter.string(choice.get($0)) }
                )
            default:
                return nil
        }
    }

    private static func scalar<T: Sendable>(
        _ key: String,
        _ value: SettingsValue<T>,
        parse: @escaping @Sendable (inout Reader, JSONValue) -> T?,
        format: @escaping @Sendable (T) -> String
    ) -> Self {
        Self(
            key: key,
            read: { reader, json in
                if let parsed = parse(&reader, json) { value.set(&reader.configuration, parsed) }
            },
            literal: { format(value.get($0)) }
        )
    }
}
