/// Texts and edits made from a seed, for the merge's tests: the same seed, the same run.
struct MergeRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64.
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    mutating func below(_ bound: Int) -> Int {
        bound <= 0 ? 0 : Int(next() % UInt64(bound))
    }

    mutating func pick<Element>(_ elements: [Element]) -> Element {
        elements[below(elements.count)]
    }

    /// What a Markdown parser can be made to trip on, in any order: fences left open, lists, indented lines, quotes, heads,
    /// rules, tables, references, lines with no ending, other line endings, characters of two UTF-16 units.
    static let scraps = [
        "# Title\n", "text\n", "more text \u{1F600}\n", "\n", "\n\n", "- item\n", "  - nested\n", "1. one\n",
        "    code\n",
        "```\n", "```swift\nlet a = 1\n", "~~~\n", "> quote\n", "---\n", "===\n", "| a | b |\n", "|---|---|\n",
        "[ref]: https://example.com\n", "<div>\n", "</div>\n", "\r\n", "line\r\n", "  \n", "\t\n", "* * *\n",
        "caf\u{E9}\n", "- [ ] task\n", "tail"
    ]

    mutating func document(scraps count: Int = 12) -> String {
        var text = ""
        for _ in 0 ..< below(count + 1) { text += pick(Self.scraps) }
        return text
    }

    /// `pieces` with some replaced, removed, or with others put in: what an edit does to a text, piece by piece.
    mutating func edited(_ pieces: [String], changes: Int, with fresh: [String]) -> [String] {
        var result = pieces
        for _ in 0 ..< changes {
            let at = below(result.count + 1)
            switch below(3) {
                case 0 where at < result.count: result[at] = pick(fresh)
                case 1 where at < result.count: result.remove(at: at)
                default: result.insert(pick(fresh), at: at)
            }
        }
        return result
    }
}
