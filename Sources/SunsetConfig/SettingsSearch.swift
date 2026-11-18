internal import Foundation
import Synchronization

public enum SettingsSearch {
    /// The entries that match `query`, best first. Every word of the query must be found, in any order, in the title or the keywords (case and accents
    /// ignored); a title that starts with the first word comes first, then one that contains it, then those found only by their keywords; ties keep the order
    /// of `entries`.
    public static func matches(_ query: String, in entries: [SettingsEntry]) -> [SettingsEntry] {
        let words = fold(query).split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard let first = words.first else { return [] }
        var scored: [(rank: Int, index: Int, entry: SettingsEntry)] = []
        for (index, entry) in entries.enumerated() {
            let (title, haystack) = folded(entry)
            guard words.allSatisfy({ haystack.contains($0) }) else { continue }
            let rank = title.hasPrefix(first) ? 0 : title.contains(first) ? 1 : 2
            scored.append((rank, index, entry))
        }
        return scored.sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }.map(\.entry)
    }

    /// The panes that hold `entries`, each once, in the order of their first entry.
    public static func panes(of entries: [SettingsEntry]) -> [String] {
        var seen: [String] = []
        for entry in entries where !seen.contains(entry.pane) { seen.append(entry.pane) }
        return seen
    }

    /// An entry's title and all its words, folded once and kept (note n15: folding every entry again on every keystroke).
    private static let cache = Mutex([String: (title: String, haystack: String)]())

    private static func folded(_ entry: SettingsEntry) -> (title: String, haystack: String) {
        let key = entry.id + "\u{1F}" + entry.title
        if let hit = cache.withLock({ $0[key] }) { return hit }
        let title = fold(entry.title)
        let made = (title, ([title] + entry.keywords.map(fold)).joined(separator: " "))
        cache.withLock { $0[key] = made }
        return made
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
