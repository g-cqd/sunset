internal import AemiJSONCore

/// How one key of the file is read and written, from the control that shows it (roadmap 0086 C, the owner's note n55): a
/// setting with a plain value (a switch, a number in a range, a choice) is declared once, in its `SettingsOption`, and the reader, the writer and the list of keys take
/// it from there. What is not a plain value is read and written by hand: texts (each with its own rules: empty for unset, an
/// address checked), colours that may be unset, lists, themes, keys kept for old files.
struct SettingCodec: Sendable {
    let key: String
    /// Reads `value` into the configuration, or says what is wrong with it.
    let read: @Sendable (inout Reader, JSONValue) -> Void
    /// The value as a JSON literal.
    let literal: @Sendable (Configuration) -> String

    /// The codecs of every option whose control holds a plain value made from a key path, by key.
    static let byKey: [String: Self] = {
        var codecs: [String: Self] = [:]
        for option in SettingsOption.all where option.keys == [option.id] {
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
                return Self(
                    key: key,
                    read: { reader, json in
                        if let flag = reader.bool(key, json) {
                            value.set(&reader.configuration, flag)
                        }
                    },
                    literal: { String(value.get($0)) }
                )
            case .number(let value, let range, _, _, _) where value.isDirect:
                return Self(
                    key: key,
                    read: { reader, json in
                        if let number = reader.number(key, json, range: range) {
                            value.set(&reader.configuration, number)
                        }
                    },
                    literal: { ConfigurationWriter.number(value.get($0)) }
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
}
