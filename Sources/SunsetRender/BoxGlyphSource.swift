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
