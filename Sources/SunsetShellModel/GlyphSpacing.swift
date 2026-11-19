/// The gap between a row's glyph and its text (owner note n63): the glyph's ink is as far from the text as from the row's leading edge (8.5 pt,
/// measured on a selected sidebar row), the glyph being 15 pt in an 18 pt frame. When the two had to match, space was added, not taken away.
package enum GlyphSpacing {
    package static let toText = Design.Optical.glyphToText
}
