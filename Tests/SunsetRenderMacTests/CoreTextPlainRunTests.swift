import SunsetRender
import Testing

@testable import SunsetRenderMac

/// A run in which shaping changes nothing is its characters side by side, pixel for pixel: the renderer then keeps no bitmap of
/// it (`GlyphSource.runIsPlain`; the review of 2026-11-15, 3.1).
@Suite("Runs that shaping does not change") struct CoreTextPlainRunTests {
    /// The characters of `text` drawn one at a time, side by side: what the renderer draws for a plain run.
    func sideBySide(_ text: String, _ source: CoreTextGlyphSource, bold: Bool, italic: Bool) -> [UInt8] {
        let metrics = source.metrics
        let count = text.unicodeScalars.count
        var side = [UInt8](repeating: 0, count: count * metrics.cellWidth * metrics.cellHeight)
        for (index, scalar) in text.unicodeScalars.enumerated() {
            guard
                let single = source.glyph(for: String(scalar), bold: bold, italic: italic, columns: 1, metrics: metrics)
            else { continue }
            for y in 0 ..< metrics.cellHeight {
                for x in 0 ..< metrics.cellWidth {
                    side[y * count * metrics.cellWidth + index * metrics.cellWidth + x] =
                        single.coverage[y * metrics.cellWidth + x]
                }
            }
        }
        return side
    }

    static let runs = [
        "renderer", "2026-11-15", "File123.swift:42", "0x7ffee4", "!==", "->", "=>", "www", "fi", "ffl", "::", "...",
        "</>", "[TODO]", "<=>", "a_b", "WAVE", "fj", "#{", "|>", "~=", "++", "**/", "ｱｲ", "a✓b", "é→ü"
    ]

    @Test(arguments: ["Menlo", "MapleMono-NF-CN-Regular", "SF Mono", "Monaco", "Courier New"])
    func `a run said to be plain is its characters side by side, pixel for pixel, in every style`(font: String) {
        let source = CoreTextGlyphSource(fontName: font, size: 28)
        let metrics = source.metrics
        var plain = 0
        for run in Self.runs {
            for (bold, italic) in [(false, false), (true, false), (false, true), (true, true)]
            where source.runIsPlain(run, bold: bold, italic: italic, metrics: metrics) {
                plain += 1
                let cells = run.unicodeScalars.count
                let whole = source.glyph(forRun: run, bold: bold, italic: italic, cells: cells, metrics: metrics)
                #expect(
                    whole?.coverage == sideBySide(run, source, bold: bold, italic: italic),
                    "\(source.fullName): \(run) (bold \(bold), italic \(italic)) is not its characters side by side"
                )
            }
        }
        #expect(plain > 0, "\(source.fullName) says no run is plain: nothing is gained")
    }

    @Test func `ordinary words are plain in a font without ligatures`() {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28)
        for run in ["renderer", "2026-11-15", "File123.swift:42", "!==", "->"] {
            #expect(source.runIsPlain(run, bold: false, italic: false, metrics: source.metrics), "\(run)")
        }
    }

    @Test func `a ligature is not plain, and is plain once ligatures are off`() {
        let on = CoreTextGlyphSource(fontName: "MapleMono-NF-CN-Regular", size: 28)
        guard on.fullName.contains("Maple") else { return }
        let off = CoreTextGlyphSource(fontName: "MapleMono-NF-CN-Regular", size: 28, ligatures: false)
        #expect(!on.runIsPlain("!==", bold: false, italic: false, metrics: on.metrics))
        #expect(!on.runIsPlain("a->b", bold: false, italic: false, metrics: on.metrics))
        #expect(off.runIsPlain("!==", bold: false, italic: false, metrics: off.metrics))
        #expect(on.runIsPlain("renderer", bold: false, italic: false, metrics: on.metrics))
    }

    @Test func `a character from another font, and one outside the basic plane, are not plain`() {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28)
        #expect(
            !source.runIsPlain("aｱb", bold: false, italic: false, metrics: source.metrics),
            "a fallback font's glyph"
        )
        #expect(!source.runIsPlain("a𝒳b", bold: false, italic: false, metrics: source.metrics))
        #expect(!source.runIsPlain("", bold: false, italic: false, metrics: source.metrics))
    }

    @Test func `a font feature that changes a character alone keeps its runs plain`() {
        let source = CoreTextGlyphSource(
            fontName: "MapleMono-NF-CN-Regular",
            size: 28,
            features: [FontFeature("zero", 1)]
        )
        guard source.fullName.contains("Maple") else { return }
        #expect(source.runIsPlain("1000", bold: false, italic: false, metrics: source.metrics))
    }
}
