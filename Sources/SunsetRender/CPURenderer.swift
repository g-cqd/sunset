public import SunsetCore

/// Draws a `Screen` into a `Surface` on the CPU: backgrounds, glyphs, decorations, the cursor. This is the reference renderer of ADR-0024 (the GPU one is
/// held to its output) and a product on its own. It redraws only what changed: the rows the screen marks dirty, the rows the cursor left and entered, and
/// everything when the palette, the size, reverse video or the blink phase changed. The caller clears the screen's dirty marks after a frame.
public final class CPURenderer: CellRenderer {
    public let metrics: RenderMetrics
    private let glyphs: any GlyphSource

    private struct GlyphKey: Hashable {
        var id: UInt32
        var cluster: Bool
        var bold: Bool
        var italic: Bool
        var wide: Bool
    }

    private var cache: [GlyphKey: GlyphBitmap?] = [:]
    private var lastCursor: CursorDrawn?
    private var lastPalette: Palette?
    private var lastReverse = false
    private var lastBlink = true
    private var lastSize: (columns: Int, rows: Int)?

    /// What one frame draws with: the screen, the cursor, the default colours (swapped by reverse video) and the blink phase.
    private struct Frame {
        var screen: Screen
        var cursor: CursorDrawn?
        var foreground: RGB
        var background: RGB
        var blinkVisible: Bool
    }

    /// Where a cell (or a double-width pair) is on the surface.
    private struct Box {
        var x: Int
        var y: Int
        var width: Int
    }

    private struct CursorDrawn: Equatable {
        var row: Int
        var column: Int
        var shape: CursorShape
    }

    public init(metrics: RenderMetrics, glyphs: any GlyphSource) {
        self.metrics = metrics
        self.glyphs = glyphs
    }

    /// Forget what was drawn: the next frame draws everything (a new surface, a lost one).
    public func invalidate() {
        lastCursor = nil
        lastPalette = nil
        lastSize = nil
    }

    /// Draws the rows that need it. `cursorVisible` is the host's blink phase for the cursor (and the program's own show/hide is respected too);
    /// `textBlinkVisible` the phase of text with the blink attribute.
    public func render(
        _ screen: Screen,
        into surface: inout Surface,
        cursorVisible: Bool = true,
        textBlinkVisible: Bool = true
    ) {
        let size = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        precondition(
            surface.width >= size.width && surface.height >= size.height,
            "the surface is smaller than the grid"
        )
        let reverse = screen.modes.reverseVideo
        let full =
            lastSize == nil || lastSize!.columns != screen.columns || lastSize!.rows != screen.rows
            || lastPalette != screen.palette
            || reverse != lastReverse || textBlinkVisible != lastBlink
        let background = Surface.pack(reverse ? screen.palette.foreground : screen.palette.background)
        if full { fill(&surface, x: 0, y: 0, width: surface.width, height: surface.height, color: background) }

        let showCursor = cursorVisible && screen.modes.cursorVisible && screen.cursorRow < screen.rows
        let cursor =
            showCursor
            ? CursorDrawn(row: screen.cursorRow, column: screen.cursorColumn, shape: screen.cursorShape) : nil
        let cursorMoved = cursor != lastCursor
        let frame = Frame(
            screen: screen,
            cursor: cursor,
            foreground: reverse ? screen.palette.background : screen.palette.foreground,
            background: reverse ? screen.palette.foreground : screen.palette.background,
            blinkVisible: textBlinkVisible
        )
        for row in 0 ..< screen.rows {
            let touchesCursor = cursorMoved && (cursor?.row == row || lastCursor?.row == row)
            guard full || touchesCursor || screen.isDirty(row: row) else { continue }
            drawRow(row, frame: frame, surface: &surface)
        }
        lastCursor = cursor
        lastPalette = screen.palette
        lastReverse = reverse
        lastBlink = textBlinkVisible
        lastSize = (screen.columns, screen.rows)
    }

    // MARK: Rows and cells

    private func drawRow(_ row: Int, frame: Frame, surface: inout Surface) {
        // The row's strip is cleared first so that nothing of an earlier frame shows through.
        fill(
            &surface,
            x: 0,
            y: metrics.paddingY + row * metrics.cellHeight,
            width: surface.width,
            height: metrics.cellHeight,
            color: Surface.pack(frame.background)
        )
        var column = 0
        while column < frame.screen.columns {
            let cell = frame.screen.cell(row: row, column: column)
            if cell.width == .spacerTail {
                column += 1
                continue
            }
            let span = cell.width == .wide && column + 1 < frame.screen.columns ? 2 : 1
            drawCell(cell, row: row, column: column, span: span, frame: frame, surface: &surface)
            column += span
        }
    }

    private func drawCell(_ cell: Cell, row: Int, column: Int, span: Int, frame: Frame, surface: inout Surface) {
        let screen = frame.screen
        let style = screen.style(of: cell)
        let palette = screen.palette
        var foreground = palette.resolve(style.foreground) ?? frame.foreground
        var background = palette.resolve(style.background) ?? frame.background
        if style.attributes.contains(.inverse) { swap(&foreground, &background) }
        if style.attributes.contains(.faint) { foreground = mix(foreground, background) }
        let cursor = frame.cursor
        let onCursor = cursor.map { $0.row == row && $0.column >= column && $0.column < column + span } ?? false
        if onCursor, cursor?.shape == .block {
            let cellBackground = background
            background = palette.cursor
            foreground = cellBackground
        }
        let box = Box(
            x: metrics.paddingX + column * metrics.cellWidth,
            y: metrics.paddingY + row * metrics.cellHeight,
            width: span * metrics.cellWidth
        )
        if background != frame.background || onCursor {
            fill(
                &surface,
                x: box.x,
                y: box.y,
                width: box.width,
                height: metrics.cellHeight,
                color: Surface.pack(background)
            )
        }
        let hidden = style.attributes.contains(.invisible) || (style.attributes.contains(.blink) && !frame.blinkVisible)
        if cell.scalar != 0, !hidden, let bitmap = bitmap(for: cell, style: style, wide: span == 2, screen: screen) {
            blit(bitmap, into: &surface, cellX: box.x, cellY: box.y, cellWidth: box.width, color: foreground)
        }
        let lineColor = palette.resolve(style.underlineColor) ?? foreground
        drawDecorations(style, box: box, surface: &surface, line: lineColor, strike: foreground)
        if onCursor, let shape = cursor?.shape, shape != .block {
            let cursorColor = Surface.pack(palette.cursor)
            if shape == .underline {
                fill(
                    &surface,
                    x: box.x,
                    y: box.y + metrics.cellHeight - 2,
                    width: box.width,
                    height: 2,
                    color: cursorColor
                )
            } else {
                fill(&surface, x: box.x, y: box.y, width: 2, height: metrics.cellHeight, color: cursorColor)
            }
        }
    }

    private func bitmap(for cell: Cell, style: CellStyle, wide: Bool, screen: Screen) -> GlyphBitmap? {
        let key = GlyphKey(
            id: cell.scalar,
            cluster: cell.isCluster,
            bold: style.attributes.contains(.bold),
            italic: style.attributes.contains(.italic),
            wide: wide
        )
        if let cached = cache[key] { return cached }
        let made = glyphs.glyph(
            for: screen.text(of: cell),
            bold: key.bold,
            italic: key.italic,
            columns: wide ? 2 : 1,
            metrics: metrics
        )
        cache[key] = .some(made)
        return made
    }

    // MARK: Pixels

    private func fill(_ surface: inout Surface, x: Int, y: Int, width: Int, height: Int, color: UInt32) {
        let x0 = max(0, x)
        let x1 = min(surface.width, x + width)
        let y0 = max(0, y)
        let y1 = min(surface.height, y + height)
        guard x0 < x1, y0 < y1 else { return }
        for row in y0 ..< y1 {
            let base = row * surface.width
            for column in x0 ..< x1 { surface.pixels[base + column] = color }
        }
    }

    /// Blends the glyph's coverage over what is there, inside the cell(s) it belongs to.
    private func blit(
        _ bitmap: GlyphBitmap,
        into surface: inout Surface,
        cellX: Int,
        cellY: Int,
        cellWidth: Int,
        color: RGB
    ) {
        for row in 0 ..< bitmap.height {
            let y = cellY + bitmap.top + row
            guard y >= cellY, y < cellY + metrics.cellHeight, y < surface.height else { continue }
            for column in 0 ..< bitmap.width {
                let x = cellX + bitmap.left + column
                guard x >= cellX, x < cellX + cellWidth, x < surface.width else { continue }
                let alpha = Int(bitmap.coverage[row * bitmap.width + column])
                if alpha == 0 { continue }
                let index = y * surface.width + x
                surface.pixels[index] = alpha == 255 ? Surface.pack(color) : blend(surface.pixels[index], color, alpha)
            }
        }
    }

    @inline(__always) private func blend(_ below: UInt32, _ color: RGB, _ alpha: Int) -> UInt32 {
        let inverse = 255 - alpha
        let red = (Int(color.red) * alpha + Int(below & 0xFF) * inverse + 127) / 255
        let green = (Int(color.green) * alpha + Int((below >> 8) & 0xFF) * inverse + 127) / 255
        let blue = (Int(color.blue) * alpha + Int((below >> 16) & 0xFF) * inverse + 127) / 255
        return Surface.pack(RGB(UInt8(red), UInt8(green), UInt8(blue)))
    }

    private func mix(_ first: RGB, _ second: RGB) -> RGB {
        RGB(
            UInt8((Int(first.red) + Int(second.red)) / 2),
            UInt8((Int(first.green) + Int(second.green)) / 2),
            UInt8((Int(first.blue) + Int(second.blue)) / 2)
        )
    }

    // MARK: Decorations

    private func drawDecorations(_ style: CellStyle, box: Box, surface: inout Surface, line: RGB, strike: RGB) {
        let (x, y, width) = (box.x, box.y, box.width)
        let thickness = metrics.lineThickness
        let packedLine = Surface.pack(line)
        switch style.underline {
            case .none: break
            case .single:
                fill(&surface, x: x, y: y + metrics.underlineY, width: width, height: thickness, color: packedLine)
            case .double:
                fill(&surface, x: x, y: y + metrics.underlineY, width: width, height: thickness, color: packedLine)
                fill(
                    &surface,
                    x: x,
                    y: max(0, y + metrics.underlineY - 2 * thickness),
                    width: width,
                    height: thickness,
                    color: packedLine
                )
            case .curly:
                let wave = [0, 1, 2, 1]
                for offset in 0 ..< width {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY - 1 + wave[offset % 4],
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
            case .dotted:
                for offset in stride(from: 0, to: width, by: 2) {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY,
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
            case .dashed:
                for offset in 0 ..< width where offset % 4 != 3 {
                    fill(
                        &surface,
                        x: x + offset,
                        y: y + metrics.underlineY,
                        width: 1,
                        height: thickness,
                        color: packedLine
                    )
                }
        }
        if style.attributes.contains(.strikethrough) {
            fill(&surface, x: x, y: y + metrics.strikeY, width: width, height: thickness, color: Surface.pack(strike))
        }
        if style.attributes.contains(.overline) {
            fill(&surface, x: x, y: y + metrics.overlineY, width: width, height: thickness, color: Surface.pack(strike))
        }
    }
}
