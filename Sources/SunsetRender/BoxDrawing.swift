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

/// A coverage canvas with rectangle and anti-aliased line helpers.
struct Canvas {
    let width: Int
    let height: Int
    var coverage: [UInt8]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        coverage = [UInt8](repeating: 0, count: width * height)
    }

    /// Fills the rectangle [x, x + w) x [y, y + h), clipped, with `value` (the larger of it and what is there).
    mutating func fill(x: Int, y: Int, width w: Int, height h: Int, value: UInt8 = 255) {
        let x0 = max(0, x)
        let x1 = min(width, x + w)
        let y0 = max(0, y)
        let y1 = min(height, y + h)
        guard x0 < x1, y0 < y1 else { return }
        for row in y0 ..< y1 {
            for column in x0 ..< x1 { coverage[row * width + column] = max(coverage[row * width + column], value) }
        }
    }

    mutating func plot(x: Int, y: Int, value: UInt8) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        coverage[y * width + x] = max(coverage[y * width + x], value)
    }
}
