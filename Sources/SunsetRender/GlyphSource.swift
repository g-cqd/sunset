/// Where glyphs come from: a font rasteriser (the platform's, behind a seam; the own font stack later, ADR-0008) or a test double. Asked once per distinct
/// glyph; the renderer keeps the answers.
public protocol GlyphSource {
    /// The coverage of `text` (one character or one grapheme cluster) for cells of `metrics`, over `columns` cells (1, or 2 for a double-width character).
    /// Nil when it draws nothing (a space).
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap?

    /// Whether this source can shape a run of cells as one piece (ligatures, contextual alternates): `glyph(forRun:...)` is then meaningful.
    var shapesRuns: Bool { get }

    /// The coverage of a run of narrow characters of one style, shaped together, over `cells` cells (the bitmap is `cells` cells wide). A ligature is one
    /// glyph over several cells; the result may also be the same as drawing the characters one by one.
    func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap?
}

extension GlyphSource {
    public var shapesRuns: Bool { false }
    public func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap?
    { nil }
}
