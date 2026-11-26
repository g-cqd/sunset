/// Where glyphs come from: a font rasteriser (the platform's, behind a seam; the own font stack later) or a test double. Asked once per distinct
/// glyph; the renderer keeps the answers.
public protocol GlyphSource: Sendable {
    /// The coverage of `text` (one character or one grapheme cluster) for cells of `metrics`, over `columns` cells (1, or 2 for a double-width character).
    /// Nil when it draws nothing (a space).
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap?

    /// Whether this source can shape a run of cells as one piece (ligatures, contextual alternates): `glyph(forRun:...)` is then meaningful.
    var shapesRuns: Bool { get }

    /// The coverage of a run of narrow characters of one style, shaped together, over `cells` cells (the bitmap is `cells` cells wide). A ligature is one
    /// glyph over several cells; the result may also be the same as drawing the characters one by one.
    func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap?

    /// Whether shaping changes nothing in this run: every character keeps the glyph it has alone, in its own cell, so that the run's bitmap would be
    /// its characters' bitmaps side by side, pixel for pixel. The renderer then draws the characters and keeps no bitmap of the run (most words are so;
    /// a bitmap a word was 100 MB after a few thousand lines of a log). False when in doubt: the run is then drawn as one piece.
    func runIsPlain(_ text: String, bold: Bool, italic: Bool, metrics: RenderMetrics) -> Bool

    /// O(1) per-character fast check: returns true if `scalar` is guaranteed never to combine or alter shape with any
    /// other character for which `asciiRunByteIsPlain` also returns true in the given style (t241). When every cell in
    /// a run satisfies this, `CPURenderer` skips string allocation, hash lookup, and CoreText shaping entirely.
    func asciiRunByteIsPlain(_ byte: UInt8, bold: Bool, italic: Bool) -> Bool
}

extension GlyphSource {
    public var shapesRuns: Bool {
        false
    }
    public func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap?
    { nil }
    public func runIsPlain(_ text: String, bold: Bool, italic: Bool, metrics: RenderMetrics) -> Bool {
        false
    }
    public func asciiRunByteIsPlain(_ byte: UInt8, bold: Bool, italic: Bool) -> Bool {
        false
    }
}
