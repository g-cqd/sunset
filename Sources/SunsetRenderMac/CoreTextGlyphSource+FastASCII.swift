internal import CoreGraphics
internal import CoreText
internal import Foundation

/// Which printable ASCII bytes (0x21...0x7E) may be drawn cell by cell without shaping, per font style (t241); see
/// `computeASCIISafeSet`.
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

    /// The safe ASCII bytes of `font` shaped with `settings`: printable bytes whose glyph alone is the font's own
    /// mapping and keeps to its cell, less any whose glyph a substitution could change in a run made only of safe bytes
    /// (`SubstitutionReach`, over the OpenType `GSUB` and AAT `morx` tables). A table it cannot read in full (malformed,
    /// an unknown format, or AAT's old `mort`) leaves none: such fonts take the shaping path (`runIsPlain`).
    static func computeASCIISafeSet(
        font: CTFont,
        settings: [FontFeature],
        lookup: (UInt16) -> AloneGlyph
    ) -> ASCIISafeSet {
        var glyphs: [UInt8: UInt16] = [:]
        for byte in UInt8(0x21) ... UInt8(0x7E) {
            let solo = lookup(UInt16(byte))
            guard let glyph = solo.glyph, solo.keepsToItsCell, mapped(font, byte) == glyph else { continue }
            glyphs[byte] = glyph
        }
        guard let kept = unchangedGlyphs(font, settings: settings, Set(glyphs.values)) else { return ASCIISafeSet() }
        var set = ASCIISafeSet()
        for (byte, glyph) in glyphs where kept.contains(glyph) { set.insert(byte) }
        return set
    }

    /// The glyphs no substitution in `font` can change in any run made only of them, nil when a table cannot be read.
    static func unchangedGlyphs(_ font: CTFont, settings: [FontFeature], _ glyphs: Set<UInt16>) -> Set<UInt16>? {
        guard CTFontCopyTable(font, CTFontTableTag(kCTFontTableMort), []) == nil else { return nil }
        do {
            var tables: [any SubstitutionTable] = []
            if let bytes = table(font, kCTFontTableGSUB) {
                tables.append(try GSUBReach(bytes) { SubstitutionReach.isApplied($0, settings: settings) })
            }
            if let bytes = table(font, kCTFontTableMorx) { tables.append(try MorxReach(bytes)) }
            // Losing a letter or digit costs more than losing punctuation, where ligatures and their contexts live.
            let letters = Set(
                glyphs.filter { glyph in
                    (UInt8(0x21) ... UInt8(0x7E))
                        .contains { byte in
                            Self.isLetterOrDigit(byte) && mapped(font, byte) == glyph
                        }
                }
            )
            return try SubstitutionReach.unchanged(glyphs, tables: tables) { removed in
                removed.reduce(0) { total, glyph in total + (letters.contains(glyph) ? 64 : 1) }
            }
        } catch {
            return nil
        }
    }

    private static func table(_ font: CTFont, _ tag: Int) -> [UInt8]? {
        guard let data = CTFontCopyTable(font, CTFontTableTag(tag), []) as Data? else { return nil }
        return [UInt8](data)
    }

    /// The font's own glyph for `byte`, from its character map.
    private static func isLetterOrDigit(_ byte: UInt8) -> Bool {
        (0x30 ... 0x39).contains(byte) || (0x41 ... 0x5A).contains(byte) || (0x61 ... 0x7A).contains(byte)
    }

    private static func mapped(_ font: CTFont, _ byte: UInt8) -> UInt16? {
        var unit = UniChar(byte)
        var glyph = CGGlyph(0)
        let found = unsafe CTFontGetGlyphsForCharacters(font, &unit, &glyph, 1)
        return found && glyph != 0 ? glyph : nil
    }
}
