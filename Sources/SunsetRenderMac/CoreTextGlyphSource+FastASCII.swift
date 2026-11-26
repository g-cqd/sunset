internal import CoreGraphics
internal import CoreText
internal import Foundation

/// Precomputes which printable ASCII bytes (0x21...0x7E) can safely bypass CoreText run shaping per font style
/// (t241: avoids paying 16–43 µs per line of new plain words when ligatures are enabled).
extension CoreTextGlyphSource {
    struct ASCIISafeSets: Sendable {
        let regular: ASCIISafeSet
        let bold: ASCIISafeSet
        let italic: ASCIISafeSet
        let boldItalic: ASCIISafeSet

        func contains(_ byte: UInt8, bold isBold: Bool, italic isItalic: Bool) -> Bool {
            let set = isBold ? (isItalic ? boldItalic : bold) : (isItalic ? italic : regular)
            return set.contains(byte)
        }
    }

    /// Bitset of printable ASCII bytes (bit `b` set for byte `b` in 0x21...0x7E) guaranteed never to trigger
    /// ligatures, contextual alternates, or cell-overflowing ink when adjacent to other safe ASCII bytes.
    struct ASCIISafeSet: Sendable {
        var low: UInt64 = 0
        var high: UInt64 = 0

        func contains(_ byte: UInt8) -> Bool {
            guard byte < 128 else { return false }
            return byte < 64 ? ((low & (1 << byte)) != 0) : ((high & (1 << (byte - 64))) != 0)
        }

        mutating func insert(_ byte: UInt8) {
            guard byte < 128 else { return }
            if byte < 64 { low |= (1 << byte) } else { high |= (1 << (byte - 64)) }
        }
    }

    private static let ligatureProbes =
        "fi fl ff ffi ffl fj ft st ct ae oe www WWW 0x1A 1x2 0o7 0b1 WAVE Ta To Va We Ya Yo"
        .split(separator: " ")
        .map(String.init)

    /// Computes the safe ASCII fast-path bitset for `font` at `cellWidth`.
    /// Checks BOTH OpenType `GSUB` and Apple AAT `morx`/`mort` substitution tables!
    static func computeASCIISafeSet(
        font: CTFont,
        cellWidth: Int,
        ligatures: Bool,
        lookup: (UInt16) -> AloneGlyph
    ) -> ASCIISafeSet {
        let hasSubstitutions = hasSubstitutionTables(font)
        if !hasSubstitutions {
            return allFittingASCII(lookup: lookup)
        }
        if !ligatures {
            let sample = String((UInt8(0x21) ... UInt8(0x7E)).map { Character(UnicodeScalar($0)) })
            return Self.isPlainShaped(sample, font: font, lookup: lookup)
                ? allFittingASCII(lookup: lookup) : ASCIISafeSet()
        }
        var tainted: Set<UInt8> = []
        for probe in ligatureProbes where !Self.isPlainShaped(probe, font: font, lookup: lookup) {
            tainted.formUnion(probe.utf8)
        }
        var set = ASCIISafeSet()
        for byte in UInt8(0x30) ... UInt8(0x7A) where isAlphaNum(byte) && !tainted.contains(byte) {
            let pair = String([Character(UnicodeScalar(byte)), Character(UnicodeScalar(byte))])
            if Self.isPlainShaped(pair, font: font, lookup: lookup) { set.insert(byte) }
        }
        return set
    }

    private static func hasSubstitutionTables(_ font: CTFont) -> Bool {
        let tags: [CTFontTableTag] = [
            CTFontTableTag(kCTFontTableGSUB),
            CTFontTableTag(kCTFontTableMorx),
            CTFontTableTag(kCTFontTableMort)
        ]
        return tags.contains { CTFontCopyTable(font, $0, []) != nil }
    }

    private static func allFittingASCII(lookup: (UInt16) -> AloneGlyph) -> ASCIISafeSet {
        var set = ASCIISafeSet()
        for byte in UInt8(0x21) ... UInt8(0x7E) {
            let solo = lookup(UInt16(byte))
            if solo.glyph != nil, solo.keepsToItsCell { set.insert(byte) }
        }
        return set
    }

    private static func isAlphaNum(_ byte: UInt8) -> Bool {
        (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
    }
}
