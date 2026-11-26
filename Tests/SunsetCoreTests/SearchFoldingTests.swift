import AemiRegex
import Testing

@testable import SunsetCore

/// Plain case-insensitive search finds what the regex engine's `(?i)` finds (t185's fast path must not change results):
/// the ASCII letters whose folding reaches outside ASCII are derived from the engine over the Basic Multilingual Plane, and must
/// be the ones the fast path leaves to it.
@Suite("Search: case folding") struct SearchFoldingTests {
    @Test func `the letters that fold beyond ASCII are exactly the ones the fast path leaves to the regex engine`()
        throws
    {
        var everyScalar: [UInt8] = []
        // The Basic Multilingual Plane: every case fold that reaches an ASCII letter is in it (Unicode's CaseFolding.txt).
        for value in 0x80 ... 0xFFFF {
            guard let scalar = Unicode.Scalar(value) else { continue }
            everyScalar.append(contentsOf: String(scalar).utf8)
        }
        var reaching: Set<UInt8> = []
        for letter in UInt8(ascii: "a") ... UInt8(ascii: "z") {
            let pattern = try Pattern("(?i)" + String(UnicodeScalar(letter)))
            var found = false
            pattern.forEachMatch(in: everyScalar) { _ in
                found = true
                return false
            }
            if found { reaching.insert(letter) }
        }
        #expect(reaching == Screen.foldsBeyondASCII, "\(reaching.map { String(UnicodeScalar($0)) }.sorted())")
    }

    @Test(arguments: ["k", "K", "s", "S", "mask", "ok"])
    func `plain search finds the Kelvin sign and the long s as the regex search does`(needle: String) {
        var t = Terminal(columns: 30, rows: 3)
        t.feed("ma\u{017F}k o\u{212A} OK mask\r\n")
        let plain = t.screen.search(SearchQuery(text: needle, isRegex: false)).matches
        let regex = t.screen.search(SearchQuery(text: needle, isRegex: true)).matches
        #expect(plain == regex, "\(needle): plain \(plain.count), regex \(regex.count)")
        #expect(!plain.isEmpty)
    }
}
