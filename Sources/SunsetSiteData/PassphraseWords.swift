import Foundation

/// The words Sunset draws passphrases from: EFF's Short Wordlist #1 (1,296 short, distinct, easy-to-type words, chosen
/// by EFF to leave out offensive and confusable ones), shipped unmodified as `Resources/eff_short_wordlist_1.txt`
/// (CC BY 4.0, see `Resources/SOURCES.md`). Each line is a four-dice roll, a tab, and a word.
public enum PassphraseWords {
    /// How many words the shipped list holds; a file that reads otherwise is refused.
    public static let expectedCount = 1_296

    /// The shipped list, read once and kept; throws when the file is missing or not the list it should be.
    public static func bundled() throws -> [String] {
        guard let words = shared else { throw CocoaError(.fileReadCorruptFile) }
        return words
    }

    /// The words of a list in EFF's format, in order; nil unless every line is a roll, a tab and a word of lowercase
    /// ASCII letters (a hyphen inside allowed, "yo-yo"), with no word twice and exactly `expectedCount` of them.
    public static func parse(_ text: String) -> [String]? {
        var words: [String] = []
        words.reserveCapacity(expectedCount)
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "\t")
            guard parts.count == 2, parts[0].allSatisfy({ ("1" ... "6").contains($0) }) else { return nil }
            let word = String(parts[1])
            guard let first = word.first, let last = word.last, first.isLetter, last.isLetter,
                word.allSatisfy({ ("a" ... "z").contains($0) || $0 == "-" })
            else { return nil }
            words.append(word)
        }
        guard words.count == expectedCount, Set(words).count == words.count else { return nil }
        return words
    }

    private static let shared: [String]? = BundledResource.text("eff_short_wordlist_1", "txt").flatMap(parse)
}
