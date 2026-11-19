import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetConfig

/// Roadmap 0086 C (the owner's note n55: "duplicated codes"): a setting with a plain value is declared once, in its option;
/// the reader, the writer and the key list take it from there.
@Suite("Settings declared once")
struct SettingCodecTests {
    /// A value that is not the default, for each kind of control.
    private func changed(_ option: SettingsOption, in configuration: inout Configuration) {
        switch option.control {
            case .toggle(let value, _): value.set(&configuration, !value.get(configuration))
            case .number(let value, let range, _, _, _):
                let middle = ((range.lowerBound + range.upperBound) / 2).rounded()
                value.set(&configuration, middle == value.get(configuration) ? range.upperBound : middle)
            case .choice(let choice, _):
                if let other = choice.items.first(where: { $0.value != choice.get(configuration) }) {
                    choice.set(&configuration, other.value)
                }
            default: break
        }
    }

    @Test func `every plain value read back as written, through the file`() throws {
        var configuration = Configuration()
        for option in SettingsOption.all where SettingCodec.byKey[option.id] != nil {
            changed(option, in: &configuration)
        }
        let text = ConfigurationWriter.text(for: configuration)
        let read = try ConfigurationParser.parse(text)
        #expect(read.issues.isEmpty, "\(read.issues)")
        for key in SettingCodec.byKey.keys.sorted() {
            let codec = try #require(SettingCodec.byKey[key])
            #expect(codec.literal(read.configuration) == codec.literal(configuration), "\(key)")
        }
        #expect(SettingCodec.byKey.count >= 95, "\(SettingCodec.byKey.count) codecs")
    }

    @Test func `a key read from its option is spelled once in the configuration's sources`() {
        // The code only: a comment may name a key, and a topic may be called as one (its own names, "web.blocking").
        let lines = RepositoryFiles.swiftFiles(in: ["Sources/SunsetConfig"])
            .flatMap { $0.text.split(separator: "\n") }
            .filter {
                let code = $0.trimmingCharacters(in: .whitespaces)
                return !code.hasPrefix("//") && !code.hasPrefix("SettingsTopic(")
            }
        var repeated: [String] = []
        for key in SettingCodec.byKey.keys.sorted() {
            let quoted = "\"\(key)\""
            let count = lines.reduce(0) { $0 + $1.components(separatedBy: quoted).count - 1 }
            if count != 1 {
                repeated.append("\(key) ×\(count)")
            }
        }
        #expect(repeated.isEmpty, "\(repeated.count) keys spelled more than once: \(repeated.prefix(10))")
    }
}
