internal import CoreGraphics
internal import CoreText
internal import Foundation

/// Which printable ASCII bytes (0x21...0x7E) may be drawn cell by cell without shaping, per font style (t241). Only a
/// font with no substitution table has any; see `computeASCIISafeSet`.
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

    /// The safe ASCII bytes of `font`: every printable byte whose glyph alone is the font's own and keeps
    /// to its cell — and only when the font has no substitution table at all (no OpenType `GSUB`, no AAT `morx` or
    /// `mort`), the one case where shaping provably cannot change a glyph by its neighbours. A font with such a table
    /// gets none: contextual rules can reach any letter (Monaspace's "texture healing" reshaped about 15% of random
    /// letter runs, 2026-11-26), and no list of probes can show their absence. Such fonts take the shaping path (`runIsPlain`).
    static func computeASCIISafeSet(font: CTFont, lookup: (UInt16) -> AloneGlyph) -> ASCIISafeSet {
        hasSubstitutionTables(font) ? ASCIISafeSet() : allFittingASCII(lookup: lookup)
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
}
