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

    var cache: [GlyphKey: GlyphBitmap?] = [:]
    var lastCursor: CursorDrawn?
    var lastPalette: Palette?
    var lastBackgroundAlpha: UInt8 = 255
    /// The surface's default background is translucent: text is blended with the kernel that handles a destination of any alpha.
    var translucent = false
    var lastReverse = false
    var lastBlink = true
    /// How many rows were drawn in all (a counter for tests and probes: a frame that changes nothing must draw nothing).
    var rowsDrawn = 0
    /// The pixel rows of the surface the last frame wrote to (the whole surface after a full redraw), nil when it wrote nothing: what a presenter has to upload.
    public internal(set) var changedPixelRows: ClosedRange<Int>?
    /// Which rows were drawn with blinking text: only those change when the blink phase does.
    var blinkRows: [Bool] = []
    var lastScrolledBack = 0
    var lastSelection: Selection?
    var lastHoveredLink: UInt16 = 0
    var lastSelectionRows: ClosedRange<Int>?
    var lastSize: (columns: Int, rows: Int)?

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
        lastHoveredLink = 0
        lastSelectionRows = nil
        lastSize = nil
        blinkRows = []
    }

    /// Draws the rows that need it. `cursorVisible` is the host's blink phase for the cursor (and the program's own show/hide is respected too);
    /// `textBlinkVisible` the phase of text with the blink attribute.
    public func render(
        _ screen: Screen,
        into surface: inout Surface,
        cursorVisible: Bool = true,
        textBlinkVisible: Bool = true,
        view: FrameView = FrameView()
    ) {
        let size = metrics.surfaceSize(columns: screen.columns, rows: screen.rows)
        precondition(
            surface.width >= size.width && surface.height >= size.height,
            "the surface is smaller than the grid"
        )
        let reverse = screen.modes.reverseVideo
        let scrolledBack = min(max(view.scrolledBack, 0), screen.scrollbackCount)
        let (selection, hoveredLink) = (view.selection, view.hoveredLink)
        let full = needsFullRedraw(screen, view: view, reverse: reverse, scrolledBack: scrolledBack)
        if blinkRows.count != screen.rows { blinkRows = [Bool](repeating: false, count: screen.rows) }
        let blinkChanged = textBlinkVisible != lastBlink
        let backgroundAlpha = view.backgroundAlpha
        translucent = backgroundAlpha < 255
        let background = Surface.pack(
            reverse ? screen.palette.foreground : screen.palette.background,
            alpha: backgroundAlpha
        )
        changedPixelRows = nil
        if full {
            fill(&surface, x: 0, y: 0, width: surface.width, height: surface.height, color: background)
            changedPixelRows = 0 ... surface.height - 1
        }

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
            selection: selection,
            hoveredLink: hoveredLink,
            backgroundAlpha: backgroundAlpha
        )
        // The rows the selection covers now or covered in the last frame are drawn again when it changed.
        let selectionRows = selectionRows(of: selection, in: frame)
        let selectionChanged = selection != lastSelection
        for row in 0 ..< screen.rows {
            let touchesCursor = cursorMoved && (cursor?.row == row || lastCursor?.row == row)
            let touchesSelection =
                selectionChanged
                && ((selectionRows?.contains(row) ?? false) || (lastSelectionRows?.contains(row) ?? false))
            let blinks = blinkChanged && blinkRows[row]
            guard full || blinks || touchesCursor || touchesSelection || screen.isDirty(row: row) else { continue }
            drawRow(row, frame: frame, surface: &surface)
        }
        remember(
            frame,
            cursor: cursor,
            reverse: reverse,
            textBlinkVisible: textBlinkVisible,
            selectionRows: selectionRows
        )
    }

    // MARK: Rows and cells

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
            y: metrics.originY + place.row * metrics.cellHeight,
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
        let blinks = style.attributes.contains(.blink)
        if blinks { blinkRows[place.row] = true }
        let hidden = style.attributes.contains(.invisible) || (blinks && !frame.blinkVisible)
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
}
