public import SunsetCore

/// Draws a `Screen` into a `Surface` on the CPU: backgrounds, glyphs, decorations, the cursor. This is the reference renderer of ADR-0024 (the GPU one is
/// held to its output) and a product on its own. It redraws only what changed: the rows the screen marks dirty, the rows the cursor left and entered, and
/// everything when the palette, the size, reverse video or the blink phase changed. The caller clears the screen's dirty marks after a frame.
public final class CPURenderer: CellRenderer {
    public let metrics: RenderMetrics
    let glyphs: any GlyphSource
    /// Shape runs of cells together (ligatures and contextual alternates) when the glyph source can; a run never spans a cell with the cursor on it.
    public let ligatures: Bool
    var runCache: [UInt64: [RunEntry]] = [:]
    var runCacheCount = 0

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
    private var lastScrolledBack = 0
    private var lastSelection: Selection?
    private var lastSelectionRows: ClosedRange<Int>?
    private var lastSize: (columns: Int, rows: Int)?

    public init(metrics: RenderMetrics, glyphs: any GlyphSource, ligatures: Bool = false) {
        self.metrics = metrics
        self.glyphs = glyphs
        self.ligatures = ligatures && glyphs.shapesRuns
    }

    /// Forget what was drawn: the next frame draws everything (a new surface, a lost one).
    public func invalidate() {
        lastCursor = nil
        lastPalette = nil
        lastScrolledBack = 0
        lastSelection = nil
        lastSelectionRows = nil
        lastSize = nil
    }

    /// Draws the rows that need it. `cursorVisible` is the host's blink phase for the cursor (and the program's own show/hide is respected too);
    /// `textBlinkVisible` the phase of text with the blink attribute.
    public func render(
        _ screen: Screen,
        into surface: inout Surface,
        cursorVisible: Bool = true,
        textBlinkVisible: Bool = true,
        scrolledBack: Int = 0,
        selection: Selection? = nil
    ) {
        let size = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        precondition(
            surface.width >= size.width && surface.height >= size.height,
            "the surface is smaller than the grid"
        )
        let reverse = screen.modes.reverseVideo
        let scrolledBack = min(max(scrolledBack, 0), screen.scrollbackCount)
        let sizeChanged = lastSize.map { $0.columns != screen.columns || $0.rows != screen.rows } ?? true
        let full =
            sizeChanged || lastPalette != screen.palette || reverse != lastReverse || textBlinkVisible != lastBlink
            || scrolledBack != lastScrolledBack || (scrolledBack > 0 && screen.hasDirtyRows)
        let background = Surface.pack(reverse ? screen.palette.foreground : screen.palette.background)
        if full { fill(&surface, x: 0, y: 0, width: surface.width, height: surface.height, color: background) }

        let showCursor =
            scrolledBack == 0 && cursorVisible && screen.modes.cursorVisible && screen.cursorRow < screen.rows
        let cursor =
            showCursor
            ? CursorDrawn(row: screen.cursorRow, column: screen.cursorColumn, shape: screen.cursorShape) : nil
        let cursorMoved = cursor != lastCursor
        let frame = Frame(
            screen: screen,
            cursor: cursor,
            foreground: reverse ? screen.palette.background : screen.palette.foreground,
            background: reverse ? screen.palette.foreground : screen.palette.background,
            blinkVisible: textBlinkVisible,
            scrolledBack: scrolledBack,
            selection: selection
        )
        // The rows the selection covers now or covered in the last frame are drawn again when it changed.
        let selectionRows = selectionRows(of: selection, in: frame)
        let selectionChanged = selection != lastSelection
        for row in 0 ..< screen.rows {
            let touchesCursor = cursorMoved && (cursor?.row == row || lastCursor?.row == row)
            let touchesSelection =
                selectionChanged
                && ((selectionRows?.contains(row) ?? false) || (lastSelectionRows?.contains(row) ?? false))
            guard full || touchesCursor || touchesSelection || screen.isDirty(row: row) else { continue }
            drawRow(row, frame: frame, surface: &surface)
        }
        lastCursor = cursor
        lastPalette = screen.palette
        lastReverse = reverse
        lastBlink = textBlinkVisible
        lastScrolledBack = scrolledBack
        lastSelection = selection
        lastSelectionRows = selectionRows
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
            let cell = frame.cell(row: row, column: column)
            if cell.width == .spacerTail {
                column += 1
                continue
            }
            if ligatures, let length = drawRun(row: row, column: column, frame: frame, surface: &surface) {
                column += length
                continue
            }
            let span = cell.width == .wide && column + 1 < frame.screen.columns ? 2 : 1
            drawCell(cell, at: Placement(row: row, column: column, span: span), frame: frame, surface: &surface)
            column += span
        }
    }

    /// The colours a style is drawn in, after inverse and faint.
    func colors(of style: CellStyle, frame: Frame) -> (foreground: RGB, background: RGB) {
        let palette = frame.screen.palette
        var foreground = palette.resolve(style.foreground) ?? frame.foreground
        var background = palette.resolve(style.background) ?? frame.background
        if style.attributes.contains(.inverse) { swap(&foreground, &background) }
        if style.attributes.contains(.faint) { foreground = mix(foreground, background) }
        return (foreground, background)
    }

    func drawCell(_ cell: Cell, at place: Placement, frame: Frame, surface: inout Surface) {
        let screen = frame.screen
        let style = screen.style(of: cell)
        let palette = screen.palette
        var (foreground, background) = colors(of: style, frame: frame)
        let selected = frame.isSelected(row: place.row, column: place.column, span: place.span)
        if selected { swap(&foreground, &background) }
        let cursor = frame.cursor
        let onCursor =
            cursor.map { $0.row == place.row && $0.column >= place.column && $0.column < place.column + place.span }
            ?? false
        if onCursor, cursor?.shape == .block {
            let cellBackground = background
            background = palette.cursor
            foreground = cellBackground
        }
        let box = Box(
            x: metrics.paddingX + place.column * metrics.cellWidth,
            y: metrics.paddingY + place.row * metrics.cellHeight,
            width: place.span * metrics.cellWidth
        )
        if background != frame.background || onCursor || selected {
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
        if place.drawGlyph, cell.scalar != 0, !hidden,
            let bitmap = bitmap(for: cell, style: style, wide: place.span == 2, screen: screen)
        {
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
        // Lines, blocks and braille are drawn to the cell, not taken from the font.
        if !cell.isCluster, let own = BuiltInGlyphs.bitmap(for: cell.scalar, metrics: metrics, columns: wide ? 2 : 1) {
            cache[key] = .some(own)
            return own
        }
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
}
