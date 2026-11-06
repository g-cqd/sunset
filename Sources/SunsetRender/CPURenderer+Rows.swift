internal import SunsetCore

extension CPURenderer {
    func drawRow(_ row: Int, frame: Frame, surface: inout Surface) {
        rowsDrawn += 1
        noteChanged(
            pixelRows: metrics.paddingY + row * metrics.cellHeight ... metrics.paddingY + (row + 1) * metrics.cellHeight
                - 1
        )
        blinkRows[row] = false
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
