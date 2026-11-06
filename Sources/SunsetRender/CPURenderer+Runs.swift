internal import SunsetCore

/// A shaped run in the cache: the scalars it was made from (to tell hash collisions apart), the style flags and the bitmap (nil: it draws nothing).
final class RunEntry {
    let scalars: [UInt32]
    let bold: Bool
    let italic: Bool
    let bitmap: GlyphBitmap?

    init(scalars: [UInt32], bold: Bool, italic: Bool, bitmap: GlyphBitmap?) {
        self.scalars = scalars
        self.bold = bold
        self.italic = italic
        self.bitmap = bitmap
    }
}

extension CPURenderer {
    /// The longest run shaped as one piece.
    static let maxRun = 32
    /// How many shaped runs are kept before the cache is emptied.
    static let runCacheLimit = 8192

    /// Whether the cell can take part in a shaped run: one narrow, plain character that is neither blank, hidden nor drawn by the renderer itself.
    private func isRunnable(_ cell: Cell, row: Int, column: Int, frame: Frame) -> Bool {
        guard cell.width == .narrow, !cell.isCluster, cell.scalar > 0x20 else { return false }
        switch cell.scalar {
            case 0x2500 ... 0x259F, 0x2800 ... 0x28FF: return false
            default: break
        }
        if let cursor = frame.cursor, cursor.row == row, cursor.column == column { return false }
        let attributes = frame.screen.style(of: cell).attributes
        return !attributes.contains(.invisible) && !(attributes.contains(.blink) && !frame.blinkVisible)
    }

    /// If a run of at least two shapeable cells with one style starts at `column`, draws it (cell backgrounds and decorations one by one, the glyphs
    /// shaped together) and returns its length; nil when there is no such run and the cell is drawn alone.
    func drawRun(row: Int, column: Int, frame: Frame, surface: inout Surface) -> Int? {
        let screen = frame.screen
        let first = screen.cell(row: row, column: column)
        guard isRunnable(first, row: row, column: column, frame: frame) else { return nil }
        var length = 1
        while column + length < screen.columns, length < Self.maxRun {
            let next = screen.cell(row: row, column: column + length)
            guard next.styleID == first.styleID, isRunnable(next, row: row, column: column + length, frame: frame)
            else { break }
            length += 1
        }
        guard length >= 2 else { return nil }
        let style = screen.style(of: first)
        let bold = style.attributes.contains(.bold)
        let italic = style.attributes.contains(.italic)
        let entry = shaped(row: row, column: column, length: length, bold: bold, italic: italic, screen: screen)
        for offset in 0 ..< length {
            let cell = screen.cell(row: row, column: column + offset)
            drawCell(
                cell,
                at: Placement(row: row, column: column + offset, span: 1, drawGlyph: false),
                frame: frame,
                surface: &surface
            )
        }
        if let bitmap = entry.bitmap {
            let colors = colors(of: style, frame: frame)
            blit(
                bitmap,
                into: &surface,
                cellX: metrics.paddingX + column * metrics.cellWidth,
                cellY: metrics.paddingY + row * metrics.cellHeight,
                cellWidth: length * metrics.cellWidth,
                color: colors.foreground
            )
        }
        return length
    }

    /// The shaped run for these cells, from the cache or made by the glyph source. The lookup compares the cells with the entry's scalars, so it neither
    /// allocates nor trusts the hash alone.
    private func shaped(row: Int, column: Int, length: Int, bold: Bool, italic: Bool, screen: Screen) -> RunEntry {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325 ^ (bold ? 1 : 0) ^ (italic ? 2 : 0)
        for offset in 0 ..< length {
            hash = (hash ^ UInt64(screen.cell(row: row, column: column + offset).scalar)) &* 0x0000_0100_0000_01B3
        }
        if let entries = runCache[hash] {
            for entry in entries where entry.bold == bold && entry.italic == italic && entry.scalars.count == length {
                var same = true
                for offset in 0 ..< length
                where entry.scalars[offset] != screen.cell(row: row, column: column + offset).scalar {
                    same = false
                    break
                }
                if same { return entry }
            }
        }
        var scalars: [UInt32] = []
        var text = String.UnicodeScalarView()
        for offset in 0 ..< length {
            let value = screen.cell(row: row, column: column + offset).scalar
            scalars.append(value)
            text.append(Unicode.Scalar(value) ?? "\u{FFFD}")
        }
        let bitmap = glyphs.glyph(forRun: String(text), bold: bold, italic: italic, cells: length, metrics: metrics)
        let entry = RunEntry(scalars: scalars, bold: bold, italic: italic, bitmap: bitmap)
        if runCacheCount >= Self.runCacheLimit {
            runCache.removeAll()
            runCacheCount = 0
        }
        runCache[hash, default: []].append(entry)
        runCacheCount += 1
        return entry
    }
}
