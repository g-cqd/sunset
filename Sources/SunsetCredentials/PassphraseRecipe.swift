internal import Foundation

/// A memorable passphrase made of words drawn uniformly at random (roadmap 0092 F): `words` of them, joined by
/// `separator`, optionally capitalised, optionally with one digit added to one word. The word list is given by the
/// caller (Sunset ships EFF's Short Wordlist #1 in `SunsetSiteData`), so the strength said is that of the list used.
public struct PassphraseRecipe: Sendable, Equatable {
    /// The fewest and most words a passphrase has.
    public static let wordRange = 3 ... 12

    public var words: Int
    public var separator: String
    public var capitalize: Bool
    public var includeNumber: Bool

    public init(words: Int = 6, separator: String = "-", capitalize: Bool = false, includeNumber: Bool = false) {
        self.words = min(max(words, Self.wordRange.lowerBound), Self.wordRange.upperBound)
        self.separator = separator
        self.capitalize = capitalize
        self.includeNumber = includeNumber
    }

    /// A passphrase from `list`, or nil when the list has fewer than two distinct words (nothing worth a secret).
    /// Every choice is uniform (`Int.random(in:using:)` rejects biased draws).
    public func generate(from list: [String], using generator: inout some RandomNumberGenerator) -> String? {
        guard Set(list).count >= 2, Set(list).count == list.count else { return nil }
        let digitSlot = includeNumber ? Int.random(in: 0 ..< words, using: &generator) : -1
        var chosen: [String] = []
        chosen.reserveCapacity(words)
        for slot in 0 ..< words {
            var word = list[Int.random(in: 0 ..< list.count, using: &generator)]
            if capitalize { word = word.prefix(1).uppercased() + word.dropFirst() }
            if slot == digitSlot { word += String(Int.random(in: 0 ... 9, using: &generator)) }
            chosen.append(word)
        }
        return chosen.joined(separator: separator)
    }

    /// The passphrase's strength in bits when drawn from a list of `listCount` distinct words: each word, plus where
    /// the digit goes and which digit it is. Capitalising every word adds nothing (it is always done).
    public func entropyBits(listCount: Int) -> Double {
        guard listCount >= 2 else { return 0 }
        let digit = includeNumber ? log2(Double(words)) + log2(10) : 0
        return Double(words) * log2(Double(listCount)) + digit
    }
}
