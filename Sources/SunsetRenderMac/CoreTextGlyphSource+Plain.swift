internal import CoreGraphics
internal import CoreText
internal import Foundation
public import SunsetRender
internal import Synchronization

/// Whether shaping changes nothing in a run (`GlyphSource.runIsPlain`): the renderer then draws its characters and keeps no bitmap of it.
extension CoreTextGlyphSource {
    /// True when, shaped together, every character of `text` is one glyph of the font itself, the glyph it has alone, in order, with its ink inside its
    /// cell: the run's bitmap would then be the characters' bitmaps side by side, pixel for pixel (a glyph is drawn at the left of its character's cell
    /// either way; ink that leaves the cell shows in a run's bitmap and is cut in a character's, hence the last condition). False for a ligature, a
    /// contextual alternate, a glyph from a fallback font, a character outside the basic plane, and whenever in doubt.
    /// - Complexity: one shaping of the run; each character's own glyph is worked out once and remembered.
    public func runIsPlain(_ text: String, bold isBold: Bool, italic isItalic: Bool, metrics: RenderMetrics) -> Bool {
        let units = Array(text.utf16)
        guard !units.isEmpty, units.count == text.unicodeScalars.count else { return false }
        let variant: UInt32 = (isBold ? 1 : 0) | (isItalic ? 2 : 0)
        let font = isBold ? (isItalic ? boldItalic : bold) : (isItalic ? italic : regular)
        guard let line = Self.line(text, font: font) else { return false }
        var next = 0
        for run in (CTLineGetGlyphRuns(line) as? [CTRun]) ?? [] {
            let count = CTRunGetGlyphCount(run)
            guard count > 0, Self.font(of: run).map({ CFEqual($0, font) }) == true else { return false }
            let (glyphs, indices) = Self.glyphs(of: run, count: count)
            for index in 0 ..< count {
                // One glyph for each character, in the text's order.
                guard indices[index] == next, next < units.count else { return false }
                let own = aloneGlyph(units[next], variant: variant, font: font, cellWidth: metrics.cellWidth)
                guard own.glyph == glyphs[index], own.keepsToItsCell else { return false }
                next += 1
            }
        }
        return next == units.count
    }

    /// A shaped run's `count` glyphs, and the index in the text of the character each comes from (read the same way to
    /// draw a run and to tell whether it is plain).
    static func glyphs(of run: CTRun, count: Int) -> (glyphs: [CGGlyph], indices: [CFIndex]) {
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var indices = [CFIndex](repeating: 0, count: count)
        unsafe CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
        unsafe CTRunGetStringIndices(run, CFRange(location: 0, length: 0), &indices)
        return (glyphs, indices)
    }

    /// The font a shaped run is in, read from the run's attributes.
    static func font(of run: CTRun) -> CTFont? {
        let attributes = CTRunGetAttributes(run)
        guard
            let raw = unsafe CFDictionaryGetValue(attributes, Unmanaged.passUnretained(kCTFontAttributeName).toOpaque())
        else { return nil }
        return unsafe Unmanaged<CTFont>.fromOpaque(raw).takeUnretainedValue()
    }

    /// What the character `unit` is alone in `font`, shaped as the renderer shapes a single cell (so that a feature that changes it alone, a slashed
    /// zero, is counted in). Worked out once for each style and character.
    private func aloneGlyph(_ unit: UInt16, variant: UInt32, font: CTFont, cellWidth: Int) -> AloneGlyph {
        let key = variant << 16 | UInt32(unit)
        if let known = alone.withLock({ $0[key] }) { return known }
        var made = AloneGlyph(glyph: nil, keepsToItsCell: false)
        let runs =
            Self.line(String(utf16CodeUnits: [unit], count: 1), font: font)
            .flatMap { CTLineGetGlyphRuns($0) as? [CTRun] } ?? []
        if runs.count == 1, CTRunGetGlyphCount(runs[0]) == 1, Self.font(of: runs[0]).map({ CFEqual($0, font) }) == true
        {
            var glyph: CGGlyph = 0
            unsafe CTRunGetGlyphs(runs[0], CFRange(location: 0, length: 1), &glyph)
            var ink = CGRect.zero
            unsafe CTFontGetBoundingRectsForGlyphs(font, .horizontal, &glyph, &ink, 1)
            // An empty glyph (none in this font draws nothing) keeps to its cell.
            made = AloneGlyph(
                glyph: glyph,
                keepsToItsCell: ink.isEmpty || (ink.minX >= 0 && ink.maxX <= CGFloat(cellWidth))
            )
        }
        alone.withLock { $0[key] = made }
        return made
    }
}
