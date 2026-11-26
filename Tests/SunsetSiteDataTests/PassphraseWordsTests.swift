import Foundation
import Testing

@testable import SunsetSiteData

/// The shipped passphrase list is EFF's Short Wordlist #1, whole and unmodified (Resources/SOURCES.md), and a file
/// that is not such a list is refused rather than drawn from.
@Suite("Passphrase words") struct PassphraseWordsTests {
    @Test func `the shipped list is EFF's short list 1: 1,296 distinct short words, first acid, last zoom`() throws {
        let words = try PassphraseWords.bundled()
        #expect(words.count == 1_296)
        #expect(Set(words).count == 1_296)
        #expect(words.first == "acid" && words.last == "zoom")
        #expect(words.allSatisfy { (3 ... 5).contains($0.count) })
        #expect(words.contains("yo-yo"))
    }

    /// A distinct three-letter word for each index below 26³.
    private static func word(_ index: Int) -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        return String([letters[index / 676 % 26], letters[index / 26 % 26], letters[index % 26]])
    }

    @Test func `a list with a repeat, a bad line, or the wrong size is refused`() {
        let good = (0 ..< 1_296).map { "1111\t\(Self.word($0))" }
        #expect(PassphraseWords.parse(good.joined(separator: "\n")) != nil)
        #expect(PassphraseWords.parse(good.dropLast().joined(separator: "\n")) == nil)
        #expect(PassphraseWords.parse((good.dropLast() + [good[0]]).joined(separator: "\n")) == nil)
        #expect(PassphraseWords.parse((good.dropLast() + ["1111 word"]).joined(separator: "\n")) == nil)
        #expect(PassphraseWords.parse((good.dropLast() + ["1111\tWord"]).joined(separator: "\n")) == nil)
        #expect(PassphraseWords.parse((good.dropLast() + ["1171\tword"]).joined(separator: "\n")) == nil)
    }
}
