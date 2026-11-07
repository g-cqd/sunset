internal import Foundation

/// One option of the Settings window, for search: what it is called, and other words people look it up by.
public struct SettingsEntry: Sendable, Equatable {
    public var id: String
    /// The pane that holds it.
    public var pane: String
    public var title: String
    public var keywords: [String]

    public init(id: String, pane: String, title: String, keywords: [String]) {
        self.id = id
        self.pane = pane
        self.title = title
        self.keywords = keywords
    }
}

public enum SettingsSearch {
    /// The entries that match `query`, best first. Every word of the query must be found, in any order, in the title or the keywords (case and accents
    /// ignored); a title that starts with the first word comes first, then one that contains it, then those found only by their keywords; ties keep the order
    /// of `entries`.
    public static func matches(_ query: String, in entries: [SettingsEntry]) -> [SettingsEntry] {
        let words = fold(query).split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard let first = words.first else { return [] }
        var scored: [(rank: Int, index: Int, entry: SettingsEntry)] = []
        for (index, entry) in entries.enumerated() {
            let title = fold(entry.title)
            let haystack = ([title] + entry.keywords.map(fold)).joined(separator: " ")
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

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
