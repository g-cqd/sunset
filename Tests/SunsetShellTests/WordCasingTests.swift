import Foundation
import SunsetConfig
import SunsetHelp
import Testing

/// In what Settings and Help say (not the words a search is found by, not an address or a file's name), a protocol's or
/// a format's name is written as its standard writes it.
@Suite("The names of protocols and formats, cased")
struct WordCasingTests {
    /// Each name, as written.
    static let names = [
        "http": "HTTP", "https": "HTTPS", "url": "URL", "urls": "URLs", "html": "HTML", "css": "CSS", "dns": "DNS",
        "json": "JSON", "csv": "CSV", "pac": "PAC", "tls": "TLS", "ssh": "SSH", "gpu": "GPU", "cpu": "CPU",
        "osc": "OSC",
        "ansi": "ANSI", "api": "API", "socks": "SOCKS", "utf-8": "UTF-8"
    ]

    /// The words written in lower case where a name is meant: not part of an address (`http://`), a file (`config.json`), or
    /// code between backticks.
    static func miscased(in text: String) -> [String] {
        var found: [String] = []
        let words = text.replacingOccurrences(of: "`[^`]*`", with: " ", options: .regularExpression)
            .components(separatedBy: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ",;()\"“”?!")))
        for raw in words {
            let word = raw.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            guard !word.contains("://"), !word.contains("/"), !(word.contains(".") && !word.hasPrefix(".")) else {
                continue
            }
            if names[word] != nil { found.append(word) }
        }
        return found
    }

    @Test func `none in the settings' titles, labels and sentences, nor in Help`() {
        var wrong: [String] = []
        for option in SettingsOption.all {
            var texts = [option.title] + [option.note].compactMap(\.self)
            if case .toggle(_, let label?) = option.control { texts.append(label) }
            if case .choice(let choice, let label) = option.control {
                texts += choice.items.map(\.label) + [label].compactMap(\.self)
            }
            for text in texts { wrong += Self.miscased(in: text).map { "\(option.id): \($0) in “\(text)”" } }
        }
        for topic in HelpTopic.allCases {
            let entry = HelpCatalog.entry(topic)
            for text in [entry.title, entry.summary] + entry.text + entry.expert {
                wrong += Self.miscased(in: text).map { "Help \(topic): \($0) in “\(text.prefix(80))”" }
            }
        }
        #expect(wrong.isEmpty, "\(wrong.count): \(wrong.joined(separator: "\n"))")
    }

    /// Every text that is shown as rich text (notes, Help's paragraphs), each with what it is.
    static var richTexts: [(String, String)] {
        var texts: [(String, String)] = []
        for option in SettingsOption.all { if let note = option.note { texts.append((option.id, note)) } }
        for topic in HelpTopic.allCases {
            let entry = HelpCatalog.entry(topic)
            texts += (entry.text + entry.expert).map { ("Help \(topic)", $0) }
        }
        return texts
    }

    @Test func `a place in Sunset is bold, a file or a path monospace; a tooltip has no markup`() {
        var wrong: [String] = []
        for (whose, text) in Self.richTexts {
            let plain = text.replacingOccurrences(of: "\\*\\*[^*]*\\*\\*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "`[^`]*`", with: "", options: .regularExpression)
            if plain.contains("Settings >") { wrong.append("\(whose): a place not bold in “\(text.prefix(70))”") }
            if plain.range(
                of: #"[A-Za-z0-9_<>-]+\.(json|md|sealed|sqlite|bak)\b|~/|[a-z0-9]+://"#,
                options: .regularExpression
            )
                != nil
            {
                wrong.append("\(whose): a file not monospace in “\(text.prefix(70))”")
            }
        }
        for topic in HelpTopic.allCases where HelpCatalog.entry(topic).summary.contains(where: { "*`_".contains($0) }) {
            wrong.append("Help \(topic): markup in its tooltip")
        }
        #expect(wrong.isEmpty, "\(wrong.count): \(wrong.joined(separator: "\n"))")
    }
}
