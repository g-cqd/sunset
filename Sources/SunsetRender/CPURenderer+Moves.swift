internal import SunsetCore

/// Scrolling by moving pixels (renderer plan 2026-11-08, item 2): rows the screen says a scroll moved unchanged (`Screen.movedFrom(row:)`) are moved on the
/// surface, as the CPU renderer would have drawn them, instead of drawn again.
extension CPURenderer {
    /// Moves the longest band of rows that scrolled by one offset, and returns, by row, whether the row's pixels are now right (nil: nothing was moved). A
    /// moved row is still drawn when the cursor is on it now or was on its source row (its picture is more than its cells). Its blinking-text mark moves with
    /// it, so that a change of the blink phase draws it again as it would have the source row. Frames that show the history, a selection or a hovered link
    /// do not move rows.
    func moveScrolledRows(_ screen: Screen, frame: Frame, surface: inout Surface) -> [Bool]? {
        guard frame.scrolledBack == 0, lastScrolledBack == 0, frame.selection == nil, lastSelection == nil,
            frame.hoveredLink == 0, lastHoveredLink == 0, let band = longestMovedBand(screen)
        else { return nil }
        let height = metrics.cellHeight
        let destinationY = metrics.originY + band.rows.lowerBound * height
        surface.apply(
            PixelMove(
                sourceY: destinationY + band.offset * height,
                destinationY: destinationY,
                height: band.rows.count * height
            )
        )
        noteChanged(pixelRows: destinationY ... destinationY + band.rows.count * height - 1)
        var placed = [Bool](repeating: false, count: screen.rows)
        let blinking = blinkRows
        for row in band.rows {
            let source = row + band.offset
            blinkRows[row] = blinking[source]
            placed[row] = row != frame.cursor?.row && source != lastCursor?.row
        }
        return placed
    }

    /// The longest run of consecutive rows that a scroll moved by the same offset (a row's source is `row + offset`).
    private func longestMovedBand(_ screen: Screen) -> (rows: ClosedRange<Int>, offset: Int)? {
        var best: (rows: ClosedRange<Int>, offset: Int)?
        var row = 0
        while row < screen.rows {
            guard screen.isDirty(row: row), let source = screen.movedFrom(row: row), source != row else {
                row += 1
                continue
            }
            let offset = source - row
            var end = row
            while end + 1 < screen.rows, screen.isDirty(row: end + 1),
                screen.movedFrom(row: end + 1) == end + 1 + offset
            {
                end += 1
            }
            if (best?.rows.count ?? 0) < end - row + 1 { best = (row ... end, offset) }
            row = end + 1
        }
        return best
    }
}
