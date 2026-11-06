import SunsetRender
import Testing

@testable import SunsetRenderMac

/// The CoreText source on this machine's fonts. Tests that need a particular font say so and pass quietly (recording nothing) when it is not installed.
@Suite("CoreText glyph source") struct CoreTextGlyphSourceTests {
    @Test func `a font gives a cell size and glyphs inside it`() {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 16)
        let metrics = source.metrics
        #expect(metrics.cellWidth >= 8 && metrics.cellHeight >= 16)
        let glyph = source.glyph(for: "A", bold: false, italic: false, columns: 1, metrics: metrics)
        #expect(glyph != nil)
        #expect(glyph?.width == metrics.cellWidth && glyph?.height == metrics.cellHeight)
        #expect(glyph?.coverage.contains { $0 > 128 } == true)
        #expect(source.glyph(for: " ", bold: false, italic: false, columns: 1, metrics: metrics) == nil)
    }

    @Test func `bold and italic are different glyphs`() {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 16)
        let metrics = source.metrics
        let regular = source.glyph(for: "H", bold: false, italic: false, columns: 1, metrics: metrics)?.coverage
        #expect(source.glyph(for: "H", bold: true, italic: false, columns: 1, metrics: metrics)?.coverage != regular)
        #expect(source.glyph(for: "H", bold: false, italic: true, columns: 1, metrics: metrics)?.coverage != regular)
    }

    @Test func `a wide character is as wide as two cells`() {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 16)
        let metrics = source.metrics
        let glyph = source.glyph(for: "日", bold: false, italic: false, columns: 2, metrics: metrics)
        #expect(glyph?.width == 2 * metrics.cellWidth)
        #expect(glyph?.coverage.contains { $0 > 128 } == true)
    }

    @Test func `a font with ligatures shapes a run differently from its characters, and the feature can be turned off`()
    {
        let on = CoreTextGlyphSource(fontName: "MapleMono-NF-CN-Regular", size: 16)
        guard on.fullName.contains("Maple") else { return }
        let off = CoreTextGlyphSource(fontName: "MapleMono-NF-CN-Regular", size: 16, ligatures: false)
        let metrics = on.metrics
        let shaped = on.glyph(forRun: "!==", bold: false, italic: false, cells: 3, metrics: metrics)?.coverage
        let unshaped = off.glyph(forRun: "!==", bold: false, italic: false, cells: 3, metrics: metrics)?.coverage
        #expect(shaped != nil && unshaped != nil)
        #expect(shaped != unshaped, "the ligature changes the pixels")
        // Without ligatures a run is the characters side by side: the same pixels as drawing them one at a time.
        var side = [UInt8](repeating: 0, count: 3 * metrics.cellWidth * metrics.cellHeight)
        for (index, character) in "!==".enumerated() {
            let single = off.glyph(for: String(character), bold: false, italic: false, columns: 1, metrics: metrics)!
            for y in 0 ..< metrics.cellHeight {
                for x in 0 ..< metrics.cellWidth {
                    side[y * 3 * metrics.cellWidth + index * metrics.cellWidth + x] =
                        single.coverage[y * metrics.cellWidth + x]
                }
            }
        }
        #expect(unshaped == side)
    }

    @Test func `an OpenType feature changes the glyph where the font has it`() {
        let plain = CoreTextGlyphSource(fontName: "MapleMono-NF-CN-Regular", size: 16, ligatures: false)
        guard plain.fullName.contains("Maple") else { return }
        let metrics = plain.metrics
        let before = plain.glyph(for: "0", bold: false, italic: false, columns: 1, metrics: metrics)?.coverage
        var differing: [String] = []
        for tag in ["zero", "cv01", "cv02", "cv03", "ss01", "ss02", "ss03", "ss04"] {
            let featured = CoreTextGlyphSource(
                fontName: "MapleMono-NF-CN-Regular",
                size: 16,
                features: [FontFeature(tag, 1)],
                ligatures: false
            )
            if featured.glyph(for: "0", bold: false, italic: false, columns: 1, metrics: metrics)?.coverage != before {
                differing.append(tag)
            }
        }
        #expect(!differing.isEmpty, "at least one of the stylistic features changes the zero (found: \(differing))")
    }
}
