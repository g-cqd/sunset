import AemiTestKit
import Foundation
import Testing

@testable import SunsetCredentials

/// Passphrases drawn from a given word list (roadmap 0092 F): only the list's words, as many as asked, every word
/// reachable, one digit when asked, and the strength said is the list's.
@Suite("Passphrase recipe") struct PassphraseRecipeTests {
    private let list = ["acid", "acorn", "acre", "acts", "afar", "affix", "aged", "agent"]

    @Test func `a passphrase is the list's words, joined, capitalised, with exactly one digit when asked`() throws {
        var rng = SeededRNG(seed: 0x5EED_2026_1126)
        let recipe = PassphraseRecipe(words: 6, separator: ".", capitalize: true, includeNumber: true)
        for _ in 0 ..< 500 {
            let phrase = try #require(recipe.generate(from: list, using: &rng))
            let parts = phrase.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            #expect(parts.count == 6)
            #expect(phrase.filter(\.isNumber).count == 1)
            for part in parts {
                let word = part.filter { !$0.isNumber }
                #expect(part.first?.isUppercase == true)
                #expect(list.contains(word.lowercased()), "\(part) is not from the list")
            }
        }
    }

    @Test func `every word of the list is drawn, none favoured beyond chance`() throws {
        var rng = SeededRNG(seed: 0xD1CE)
        let recipe = PassphraseRecipe(words: 3)
        var counts: [String: Int] = [:]
        for _ in 0 ..< 8_000 {
            let phrase = try #require(recipe.generate(from: list, using: &rng))
            for word in phrase.split(separator: "-") { counts[String(word), default: 0] += 1 }
        }
        // 24,000 draws over 8 words: 3,000 expected each; ±10% is more than 12 standard deviations away.
        #expect(Set(counts.keys) == Set(list))
        #expect(counts.values.allSatisfy { (2_700 ... 3_300).contains($0) }, "\(counts)")
    }

    @Test func `strength is the list's: words times log2 of its size, plus the digit's place and value`() {
        let six = PassphraseRecipe(words: 6, includeNumber: true)
        #expect(abs(six.entropyBits(listCount: 1_296) - (6 * log2(1_296) + log2(6) + log2(10))) < 1e-9)
        #expect(abs(PassphraseRecipe(words: 6).entropyBits(listCount: 1_296) - 62.039) < 0.001)
        #expect(PassphraseRecipe(words: 1).words == PassphraseRecipe.wordRange.lowerBound)
        #expect(PassphraseRecipe(words: 99).words == PassphraseRecipe.wordRange.upperBound)
    }

    @Test func `a list with repeats or fewer than two words gives nothing`() {
        var rng = SeededRNG(seed: 1)
        let recipe = PassphraseRecipe()
        #expect(recipe.generate(from: [], using: &rng) == nil)
        #expect(recipe.generate(from: ["only"], using: &rng) == nil)
        #expect(recipe.generate(from: ["same", "same", "other"], using: &rng) == nil)
    }
}
