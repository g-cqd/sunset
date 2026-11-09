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
            guard
                let single = off.glyph(for: String(character), bold: false, italic: false, columns: 1, metrics: metrics)
            else {
                Issue.record("no glyph for \(character)")
                return
            }
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

    /// Columns of a bitmap that have ink.
    private func inkColumns(_ glyph: GlyphBitmap) -> ClosedRange<Int>? {
        let columns = (0 ..< glyph.width)
            .filter { x in (0 ..< glyph.height).contains { glyph.coverage[$0 * glyph.width + x] > 0 } }
        guard let first = columns.first, let last = columns.last else { return nil }
        return first ... last
    }

    @Test func `a symbol wider than its cell is made to fit, not cut`() throws {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
        let metrics = source.metrics
        // Swift Testing's status icons: SF Symbols in the supplementary private use area, from a fallback font, wider than a Menlo cell.
        for symbol in ["\u{101C5B}", "\u{1008A4}", "\u{1007C8}"] {
            let glyph = try #require(
                source.glyph(for: symbol, bold: false, italic: false, columns: 1, metrics: metrics)
            )
            let ink = try #require(inkColumns(glyph))
            #expect(
                ink.lowerBound > 0 && ink.upperBound < glyph.width - 1,
                "\(symbol): ink \(ink) in \(glyph.width) columns is cut at an edge"
            )
        }
        // Text of the main font is not touched: an M fills its cell as before.
        let letter = try #require(source.glyph(for: "M", bold: false, italic: false, columns: 1, metrics: metrics))
        #expect(try #require(inkColumns(letter)).count > metrics.cellWidth / 2)
    }

    @Test func `in a shaped run a symbol keeps to its own cell`() throws {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
        let metrics = source.metrics
        let run = try #require(
            source.glyph(forRun: "[\u{101C5B}]", bold: false, italic: false, cells: 3, metrics: metrics)
        )
        // The symbol's cell is the second: no ink of it in the third cell's first columns, where the bracket's ink is only its own.
        let alone = try #require(source.glyph(forRun: "[ ]", bold: false, italic: false, cells: 3, metrics: metrics))
        let third = 2 * metrics.cellWidth ..< 2 * metrics.cellWidth + 3
        for x in third {
            for y in 0 ..< run.height {
                #expect(run.coverage[y * run.width + x] == alone.coverage[y * alone.width + x], "column \(x) row \(y)")
            }
        }
    }
}
