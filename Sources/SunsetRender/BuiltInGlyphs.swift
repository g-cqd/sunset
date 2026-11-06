/// Box drawing, block elements and braille drawn to the cell instead of taken from a font, so that lines meet at the cell edges and fills reach them whatever the
/// font's metrics are (a font's cell is rarely the same height as its line, and the lines then break). Coverage bitmaps the size of the cell.
enum BuiltInGlyphs {
    /// A built-in glyph for `scalar`, or nil when the font should draw it.
    static func bitmap(for scalar: UInt32, metrics: RenderMetrics, columns: Int) -> GlyphBitmap? {
        let width = metrics.cellWidth * columns
        let height = metrics.cellHeight
        var canvas = Canvas(width: width, height: height)
        switch scalar {
            case 0x2500 ... 0x257F: guard BoxDrawing.draw(scalar, into: &canvas, metrics: metrics) else { return nil }
            case 0x2580 ... 0x259F: BlockElements.draw(scalar, into: &canvas)
            case 0x2800 ... 0x28FF: Braille.draw(scalar, into: &canvas)
            default: return nil
        }
        return GlyphBitmap(width: width, height: height, left: 0, top: 0, coverage: canvas.coverage)
    }
}
