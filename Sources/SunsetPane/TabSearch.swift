/// Ranks open tabs against what the user typed in the command bar. Pure: the app gives each tab's searchable fields (title, directory, command) and gets the
/// order back.
public enum TabSearch {
    public struct Candidate: Sendable, Equatable {
        public let id: Int
        public let fields: [String]
        public init(id: Int, fields: [String]) {
            self.id = id
            self.fields = fields
        }
    }

    /// The ids of the candidates that match, best first. The query is split into words and every word must match some field of the candidate (letters in
    /// order, not necessarily together, ignoring case); a run of the word scores above spread letters, a match at the start of a field or of a word above one
    /// in the middle. Equal scores keep the order the candidates came in. An empty query keeps everything in order.
    public static func rank(query: String, candidates: [Candidate]) -> [Int] {
        let words = query.lowercased().split(separator: " ").map(Array.init)
        guard !words.isEmpty else { return candidates.map(\.id) }
        var scored: [(id: Int, score: Int, order: Int)] = []
        for (order, candidate) in candidates.enumerated() {
            var total = 0
            var matchesAll = true
            for word in words {
                guard let best = candidate.fields.compactMap({ score(word, in: Array($0.lowercased())) }).max() else {
                    matchesAll = false
                    break
                }
                total += best
            }
            if matchesAll { scored.append((candidate.id, total, order)) }
        }
        return scored.sorted { ($1.score, $0.order) < ($0.score, $1.order) }.map(\.id)
    }

    /// The selected row after `steps` rows, going round (an index that is too far is brought inside).
    public static func moved(_ index: Int, by steps: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (((min(max(index, 0), count - 1) + steps) % count) + count) % count
    }

    /// nil when the letters of `word` are not in `text` in order.
    private static func score(_ word: [Character], in text: [Character]) -> Int? {
        if let start = find(word, in: text) { return 1000 + boundary(start, in: text) }
        var at = 0
        var total = 0
        var previous = -2
        for letter in word {
            guard let found = text[at...].firstIndex(of: letter) else { return nil }
            total += found == previous + 1 ? 3 : 1
            total += boundary(found, in: text) / 10
            previous = found
            at = found + 1
        }
        return total
    }

    /// Where `word` occurs in `text` as a run, preferring an occurrence at the start of a word.
    private static func find(_ word: [Character], in text: [Character]) -> Int? {
        guard word.count <= text.count else { return nil }
        var first: Int?
        for start in 0 ... (text.count - word.count) where Array(text[start ..< start + word.count]) == word {
            if boundary(start, in: text) > 0 { return start }
            first = first ?? start
        }
        return first
    }

    /// 100 at the start of the text, 50 at the start of a word, 0 elsewhere.
    private static func boundary(_ index: Int, in text: [Character]) -> Int {
        if index == 0 { return 100 }
        return " /-_.".contains(text[index - 1]) ? 50 : 0
    }
}
