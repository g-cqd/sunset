internal import SunsetCore

extension CPURenderer {
    /// The longest run shaped as one piece.
    static let maxRun = 32
    /// How many shaped runs are kept before the cache is emptied.
    static let runCacheLimit = 8192

    /// Whether the cell can take part in a shaped run: one narrow, plain character that is neither blank, hidden nor drawn by the renderer itself.
    private func isRunnable(_ cell: Cell, row: Int, column: Int, frame: Frame) -> Bool {
        // A symbol of the private use areas is drawn alone (it may spill over the next cell: `spills`), never shaped with its neighbours.
        guard cell.width == .narrow, !cell.isCluster, cell.scalar > 0x20, !Self.isPrivateUse(cell.scalar) else {
            return false
        }
        switch cell.scalar {
            case 0x2500 ... 0x259F, 0x2800 ... 0x28FF: return false
            default: break
        }
        if let cursor = frame.cursor, cursor.row == row, cursor.column == column { return false }
        if frame.isSelected(row: row, column: column) { return false }
        if frame.searchHighlight(row: row, column: column, span: 1) != .none { return false }
        let attributes = frame.style(of: cell).attributes
        return !attributes.contains(.invisible) && !(attributes.contains(.blink) && !frame.blinkVisible)
    }

    /// If a run of at least two shapeable cells with one style starts at `column`, draws it (cell backgrounds and decorations one by one, the glyphs
    /// shaped together, or each cell's own glyph when shaping changes nothing in the run) and returns its length; nil when there is no such run and the
    /// cell is drawn alone.
    func drawRun(
        row: Int,
        column: Int,
        cells: RowCells,
        frame: Frame,
        walk: inout Walk,
        surface: inout Surface
    ) -> Int? {
        let first = cells[column]
        guard isRunnable(first, row: row, column: column, frame: frame) else { return nil }
        var length = 1
        while column + length < frame.columns, length < Self.maxRun {
            let next = cells[column + length]
            guard next.styleID == first.styleID, isRunnable(next, row: row, column: column + length, frame: frame)
            else { break }
            length += 1
        }
        guard length >= 2 else { return nil }
        let style = frame.style(of: first)
        let (bold, italic) = (style.attributes.contains(.bold), style.attributes.contains(.italic))
        let range = column ..< column + length
        let entry: RunEntry? =
            isFastPlainASCII(cells: cells, columns: range, bold: bold, italic: italic)
            ? nil : shaped(cells: cells, columns: range, bold: bold, italic: italic, frame: frame, table: &walk.glyphs)
        let drawIndividually = entry?.plain ?? true
        for col in range {
            drawCell(
                cells[col],
                at: Placement(row: row, column: col, span: 1, drawGlyph: drawIndividually),
                frame: frame,
                walk: &walk,
                surface: &surface
            )
        }
        if let glyph = entry?.glyph, glyph != 0, cellPass.drawsMarks {
            let colors = Self.colors(of: style, frame: frame)
            blit(
                glyph,
                of: walk.glyphs,
                into: &surface,
                cell: Box(
                    x: metrics.paddingX + column * metrics.cellWidth,
                    y: metrics.originY + row * metrics.cellHeight,
                    width: length * metrics.cellWidth
                ),
                color: colors.foreground
            )
        }
        return length
    }

    private func isFastPlainASCII(cells: RowCells, columns: Range<Int>, bold: Bool, italic: Bool) -> Bool {
        for col in columns {
            let scalar = cells[col].scalar
            if scalar >= 128
                || !glyphs.asciiRunByteIsPlain(UInt8(truncatingIfNeeded: scalar), bold: bold, italic: italic)
            {
                return false
            }
        }
        return true
    }

    /// The shaped run for these cells, from the cache or made by the glyph source. The lookup compares the cells with the entry's scalars, so it neither
    /// allocates nor trusts the hash alone.
    private func shaped(
        cells: RowCells,
        columns: Range<Int>,
        bold: Bool,
        italic: Bool,
        frame: Frame,
        table: inout GlyphTable
    ) -> RunEntry {
        let (column, length) = (columns.lowerBound, columns.count)
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325 ^ (bold ? 1 : 0) ^ (italic ? 2 : 0)
        for offset in 0 ..< length {
            hash = (hash ^ UInt64(cells[column + offset].scalar)) &* 0x0000_0100_0000_01B3
        }
        if let entries = runCache[hash] {
            for entry in entries where entry.bold == bold && entry.italic == italic && entry.scalars.count == length {
                var same = true
                for offset in 0 ..< length
                where entry.scalars[offset] != cells[column + offset].scalar {
                    same = false
                    break
                }
                if same { return entry }
            }
        }
        var scalars: [UInt32] = []
        var text = String.UnicodeScalarView()
        for offset in 0 ..< length {
            let value = cells[column + offset].scalar
            scalars.append(value)
            text.append(Unicode.Scalar(value) ?? "\u{FFFD}")
        }
        // A run that shaping does not change has no bitmap of its own: its cells are drawn with their own glyphs, which every other run shares.
        let plain = glyphs.runIsPlain(String(text), bold: bold, italic: italic, metrics: metrics)
        let bitmap =
            plain
            ? nil : glyphs.glyph(forRun: String(text), bold: bold, italic: italic, cells: length, metrics: metrics)
        let entry = RunEntry(scalars: scalars, bold: bold, italic: italic, glyph: table.number(bitmap), plain: plain)
        if runCacheCount >= Self.runCacheLimit {
            runCache.removeAll()
            runCacheCount = 0
        }
        runCache[hash, default: []].append(entry)
        runCacheCount += 1
        return entry
    }
}
