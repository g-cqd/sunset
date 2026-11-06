/// A glyph as coverage: one byte per pixel, 0 nothing and 255 fully covered, `width` x `height`, placed `left` pixels from the left of its cell and `top`
/// pixels from the top. A wide glyph is as wide as its two cells.
public final class GlyphBitmap: Sendable {
    public let width: Int
    public let height: Int
    public let left: Int
    public let top: Int
    public let coverage: [UInt8]

    public init(width: Int, height: Int, left: Int, top: Int, coverage: [UInt8]) {
        precondition(coverage.count == width * height, "one coverage byte per pixel")
        self.width = width
        self.height = height
        self.left = left
        self.top = top
        self.coverage = coverage
    }
}

/// Where glyphs come from: a font rasteriser (the platform's, behind a seam; the own font stack later, ADR-0008) or a test double. Asked once per distinct
/// glyph; the renderer keeps the answers.
public protocol GlyphSource {
    /// The coverage of `text` (one character or one grapheme cluster) for cells of `metrics`, over `columns` cells (1, or 2 for a double-width character).
    /// Nil when it draws nothing (a space).
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap?
}

/// A source with no letterforms, for tests and as a fallback: every printable scalar is a filled box inset by two pixels, so presence and place can be
/// checked exactly; the pixel in the box's top left corner carries a value derived from the scalar, so which glyph was drawn can be told too.
public struct BoxGlyphSource: GlyphSource {
    public init() {}

    public func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap?
    {
        guard let scalar = text.unicodeScalars.first, scalar.value > 0x20 else { return nil }
        let width = metrics.cellWidth * columns - 4
        let height = metrics.cellHeight - 4
        guard width > 0, height > 0 else { return nil }
        var coverage = [UInt8](repeating: 255, count: width * height)
        // The marker: not fully covered, never zero, different for different scalars.
        coverage[0] = UInt8(1 + scalar.value % 250)
        return GlyphBitmap(width: width, height: height, left: 2, top: 2, coverage: coverage)
    }
}
