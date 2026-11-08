internal import SunsetCore

extension CPURenderer {
    func drawRow(_ row: Int, frame: Frame, walk: inout Walk, surface: inout Surface) {
        rowsDrawn += 1
        noteChanged(
            pixelRows: metrics.originY + row * metrics.cellHeight ... metrics.originY + (row + 1) * metrics.cellHeight
                - 1
        )
        blinkRows[row] = false
        // The row's strip is cleared first so that nothing of an earlier frame shows through.
        fill(
            &surface,
            x: 0,
            y: metrics.originY + row * metrics.cellHeight,
            width: surface.width,
            height: metrics.cellHeight,
            color: Surface.pack(frame.background, alpha: frame.backgroundAlpha)
        )
        let plainRow = frame.cursor?.row != row && frame.selection == nil && frame.hoveredLink == 0
        let cells = frame.row(row)
        var column = 0
        while column < frame.columns {
            let cell = cells[column]
            if cell.width == .spacerTail {
                column += 1
                continue
            }
            if ligatures,
                let length = drawRun(
                    row: row,
                    column: column,
                    cells: cells,
                    frame: frame,
                    walk: &walk,
                    surface: &surface
                )
            {
                column += length
                continue
            }
            // A blank cell in the default style, with no cursor, selection or link on the row, draws nothing: the strip was cleared to the background already.
            if cell.styleID == 0, cell.width == .narrow, cell.scalar == 0 || cell.scalar == 0x20, plainRow {
                column += 1
                continue
            }
            let span = cell.width == .wide && column + 1 < frame.columns ? 2 : 1
            drawCell(
                cell,
                at: Placement(row: row, column: column, span: span),
                frame: frame,
                walk: &walk,
                surface: &surface
            )
            column += span
        }
        if frame.hoveredLink != 0 { underlineHoveredLink(row: row, frame: frame, surface: &surface) }
    }

    func noteChanged(pixelRows rows: ClosedRange<Int>) {
        if let known = changedPixelRows {
            changedPixelRows = min(known.lowerBound, rows.lowerBound) ... max(known.upperBound, rows.upperBound)
        } else {
            changedPixelRows = rows
        }
    }
}
