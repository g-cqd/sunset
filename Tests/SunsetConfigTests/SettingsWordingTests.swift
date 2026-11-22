import Foundation
import Testing

@testable import SunsetConfig

/// Settings are worded as settings are (docs/design/0005-settings-wording.md): every section, group, option, label,
/// menu value and note of `SettingsSection.all`, by the rules read from VMRunner and System Settings.
@Suite("Settings' wording")
struct SettingsWordingTests {
    /// A piece of text and where it is, for the failure's message.
    struct Text {
        let place: String
        let text: String
    }

    /// The names: sections, groups, option titles, labels and menu values.
    static var names: [Text] {
        var names: [Text] = []
        for section in SettingsSection.all {
            names.append(Text(place: "section \(section.id)", text: section.title))
            for topic in section.topics {
                names.append(Text(place: "group \(topic.id)", text: topic.title))
                for option in topic.options {
                    names.append(Text(place: option.id, text: option.title))
                    names += labels(of: option)
                }
            }
        }
        return names
    }

    static func labels(of option: SettingsOption) -> [Text] {
        switch option.control {
            case .toggle(_, let label):
                return label.map { [Text(place: "\(option.id) label", text: $0)] } ?? []
            case .choice(let choice, let label):
                let named = label.map { [Text(place: "\(option.id) label", text: $0)] } ?? []
                return named + choice.items.map { Text(place: "\(option.id) value", text: $0.label) }
            default:
                return []
        }
    }

    static var notes: [Text] {
        SettingsOption.all.compactMap { option in option.note.map { Text(place: option.id, text: $0) } }
    }

    @Test func `no name starts with an article`() {
        let found = Self.names.filter { $0.text.range(of: #"^(The|A|An) "#, options: .regularExpression) != nil }
        #expect(found.isEmpty, "\(found.map { "\($0.place): \($0.text)" })")
    }

    @Test func `no name explains itself in parentheses, nor is prefixed by its group`() {
        let found = Self.names.filter { $0.text.contains("(") || $0.text.contains(": ") }
        #expect(found.isEmpty, "\(found.map { "\($0.place): \($0.text)" })")
    }

    @Test func `no name is a fragment its values finish`() {
        let endings = [" the", " in", " to", " at", " for", " goes", " shows", " is", " with", " see", " as"]
        let found = Self.names.filter { name in endings.contains { name.text.hasSuffix($0) } }
        #expect(found.isEmpty, "\(found.map { "\($0.place): \($0.text)" })")
    }

    @Test func `one spelling, the system's`() {
        let british = #"(?i)\b(colour|favourite|grey|centre|behaviour)"#
        let found = (Self.names + Self.notes).filter { $0.text.range(of: british, options: .regularExpression) != nil }
        #expect(found.isEmpty, "\(found.map { "\($0.place): \($0.text)" })")
    }

    @Test func `a note is one or two sentences of at most 200 characters`() {
        let found = Self.notes.filter { note in
            let sentences = note.text.components(separatedBy: ". ").count
            return note.text.count > 200 || sentences > 2 || !note.text.hasSuffix(".")
        }
        #expect(found.isEmpty, "\(found.map { "\($0.place) (\($0.text.count)): \($0.text)" })")
    }
}
