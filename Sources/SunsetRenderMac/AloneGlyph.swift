internal import CoreGraphics

/// What a character is when it is drawn alone in a font: its glyph, and whether the glyph's ink stays within its cell. A run in
/// which every character keeps this glyph, with its ink in its cell, is its characters side by side (`runIsPlain`).
struct AloneGlyph: Sendable {
    /// Nil when the character alone is not one glyph of the font itself (another font's, several glyphs, none).
    var glyph: CGGlyph?
    var keepsToItsCell: Bool
}
