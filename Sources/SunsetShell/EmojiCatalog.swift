package import Foundation

/// The emoji a person can pick as an icon (the owner, 2026-11-17), read from the system's own names (`CoreEmoji`'s
/// `AppleName.strings`: some 1,900, with the flags and the joined ones; no skin tones). The files are the system's, not an
/// API: when they are missing or change shape there is no emoji in the picker, and the Character Viewer is still a button
/// away.
///
/// The system gives the names and not, in a form that can be read, their order or their categories: they are listed faces
/// first, then by where Unicode has them, flags last; and found by name.
package struct EmojiCatalog: Sendable {
    package struct Emoji: Sendable, Equatable, Identifiable {
        package let text: String
        package let name: String
        /// The words of its name in lower case, made once (a search is made at each key typed).
        let words: [String]
        package var id: String {
            text
        }

        package init(text: String, name: String) {
            self.text = text
            self.name = name
            words = name.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        }
    }

    package static let systemResources = URL(
        fileURLWithPath: "/System/Library/PrivateFrameworks/CoreEmoji.framework/Versions/A/Resources"
    )

    package let emoji: [Emoji]

    package init(emoji: [Emoji]) {
        self.emoji = emoji
    }

    /// Reads the catalog from `resources` (the system's by default).
    package static func load(from resources: URL = systemResources) -> EmojiCatalog {
        guard let data = try? Data(contentsOf: resources.appending(path: "en.lproj/AppleName.strings")),
            let names = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else { return EmojiCatalog(emoji: []) }
        let all = names.compactMap { text, name in text.isEmpty ? nil : Emoji(text: text, name: name) }
        return EmojiCatalog(emoji: all.sorted { rank($0.text).lexicographicallyPrecedes(rank($1.text)) })
    }

    /// Where an emoji stands: its group, then its scalars. The groups: faces; more faces and people; the newer ones;
    /// nature, food and things; transport; everything else; flags.
    private static func rank(_ text: String) -> [UInt32] {
        let scalars = text.unicodeScalars.map(\.value)
        let first = scalars.first ?? 0
        let group: UInt32 =
            switch first {
                case 0x1F1E6 ... 0x1F1FF: 6
                case 0x1F600 ... 0x1F64F: 0
                case 0x1F900 ... 0x1F9FF: 1
                case 0x1FA00 ... 0x1FAFF: 2
                case 0x1F300 ... 0x1F5FF: 3
                case 0x1F680 ... 0x1F6FF: 4
                default: 5
            }
        return [group] + scalars
    }

    /// The emoji for what was typed: every word typed must begin a word of the name. A word that is whole scores above a
    /// beginning, a short name above a long one; the catalog's order otherwise, and for nothing typed.
    package func search(_ query: String) -> [Emoji] {
        let typed = query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard !typed.isEmpty else { return emoji }
        var scored: [(index: Int, score: Int)] = []
        for (index, one) in emoji.enumerated() {
            var total = 0
            for word in typed {
                let best = one.words.contains(word) ? 100 : (one.words.contains { $0.hasPrefix(word) } ? 60 : 0)
                guard best > 0 else {
                    total = 0
                    break
                }
                total += best
            }
            if total > 0 { scored.append((index, total * 10 - one.words.count)) }
        }
        return scored.sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
            .map { emoji[$0.index] }
    }
}
