internal import SunsetCore

/// A cell drawn: its background, its glyph, its decorations, the cursor over it.
extension CPURenderer {
    func drawCell(_ cell: Cell, at place: Placement, frame: Frame, walk: inout Walk, surface: inout Surface) {
        let style = walk.styles.style(cell.styleID, in: frame)
        var (foreground, background) = (style.foreground, style.background)
        let selected =
            frame.selection != nil && frame.isSelected(row: place.row, column: place.column, span: place.span)
        if selected { swap(&foreground, &background) }
        let cursor = frame.cursor
        let onCursor =
            cursor.map { $0.row == place.row && $0.column >= place.column && $0.column < place.column + place.span }
            ?? false
        if onCursor, cursor?.shape == .block {
            let cellBackground = background
            background = frame.palette.cursor
            foreground = cellBackground
        }
        let box = Box(
            x: metrics.paddingX + place.column * metrics.cellWidth,
            y: metrics.originY + place.row * metrics.cellHeight,
            width: place.span * metrics.cellWidth
        )
        // A bar or underline cursor does not cover the cell: its background is only drawn if it differs from the window's (an opaque fill of the default
        // background would hide a translucent window behind the cell).
        let coveredByCursor = onCursor && cursor?.shape == .block
        if cellPass.drawsBackgrounds, background != frame.background || coveredByCursor || selected {
            fill(
                &surface,
                x: box.x,
                y: box.y,
                width: box.width,
                height: metrics.cellHeight,
                color: Surface.pack(background)
            )
        }
        if style.blinks { blinkRows[place.row] = true }
        guard cellPass.drawsMarks else { return }
        if place.drawGlyph, cell.scalar != 0, !style.hidden,
            case let glyph = glyph(for: cell, style: style, wide: place.span == 2, frame: frame, table: &walk.glyphs),
            glyph != 0
        {
            blit(glyph, of: walk.glyphs, into: &surface, cell: box, color: foreground)
        }
        if style.decorated {
            drawDecorations(
                frame.style(of: cell),
                box: box,
                surface: &surface,
                line: style.line ?? foreground,
                strike: foreground
            )
        }
        if onCursor, let shape = cursor?.shape, shape != .block {
            drawThinCursor(shape, box: box, color: Surface.pack(frame.palette.cursor), surface: &surface)
        }
    }

    /// A bar or underline cursor, over the cell already drawn.
    fileprivate func drawThinCursor(_ shape: CursorShape, box: Box, color: UInt32, surface: inout Surface) {
        if shape == .underline {
            fill(&surface, x: box.x, y: box.y + metrics.cellHeight - 2, width: box.width, height: 2, color: color)
        } else {
            fill(&surface, x: box.x, y: box.y, width: 2, height: metrics.cellHeight, color: color)
        }
    }

    /// The cursor as drawn: none while the window is scrolled back, in the host's hidden blink phase, hidden by the program, or
    /// below the grid.
    static func cursor(of screen: Screen, scrolledBack: Int, visible: Bool) -> CursorDrawn? {
        let shown = scrolledBack == 0 && visible && screen.modes.cursorVisible && screen.cursorRow < screen.rows
        return shown ? CursorDrawn(row: screen.cursorRow, column: screen.cursorColumn, shape: screen.cursorShape) : nil
    }
}
