extension Screen {
    /// The row limits cursor movement is clamped to: the scroll region when the cursor is inside it, else the whole screen.
    private var verticalLimits: ClosedRange<Int> {
        row >= top && row <= bottom ? top ... bottom : 0 ... rows - 1
    }

    mutating func moveUp(_ count: Int) {
        pendingWrap = false
        row = max(verticalLimits.lowerBound, row - count)
    }

    mutating func moveDown(_ count: Int) {
        pendingWrap = false
        row = min(verticalLimits.upperBound, row + count)
    }

    mutating func moveRight(_ count: Int) {
        pendingWrap = false
        column = min(columns - 1, column + count)
    }

    mutating func moveLeft(_ count: Int) {
        pendingWrap = false
        column = max(0, column - count)
    }

    /// CUP/HVP: 1-based, relative to the scroll region in origin mode, clamped.
    mutating func moveTo(row targetRow: Int, column targetColumn: Int) {
        pendingWrap = false
        setRow(targetRow - 1)
        column = min(columns - 1, max(0, targetColumn - 1))
    }

    /// Sets the row from a 0-based position that origin mode makes relative to the top margin.
    mutating func setRow(_ position: Int) {
        if modes.origin {
            row = min(bottom, max(top, top + position))
        } else {
            row = min(rows - 1, max(0, position))
        }
    }

    mutating func carriageReturn() {
        pendingWrap = false
        column = 0
    }

    mutating func backspace() {
        pendingWrap = false
        column = max(0, column - 1)
    }

    mutating func tab(forward count: Int) {
        pendingWrap = false
        for _ in 0 ..< count {
            var next = column + 1
            while next < columns - 1, !tabStops[next] { next += 1 }
            column = min(next, columns - 1)
        }
    }

    mutating func tab(backward count: Int) {
        pendingWrap = false
        for _ in 0 ..< count {
            var previous = column - 1
            while previous > 0, !tabStops[previous] { previous -= 1 }
            column = max(previous, 0)
        }
    }

    mutating func saveCursor() {
        saved = SavedCursor(
            column: column,
            row: row,
            pendingWrap: pendingWrap,
            pen: pen,
            originMode: modes.origin,
            charsets: charsets,
            shifted: shifted
        )
    }

    mutating func restoreCursor() {
        let state =
            saved
            ?? SavedCursor(
                column: 0,
                row: 0,
                pendingWrap: false,
                pen: CellStyle(),
                originMode: false,
                charsets: (.ascii, .ascii),
                shifted: false
            )
        column = min(state.column, columns - 1)
        row = min(state.row, rows - 1)
        pendingWrap = state.pendingWrap
        pen = state.pen
        modes.origin = state.originMode
        charsets = state.charsets
        shifted = state.shifted
        penChanged()
    }

    /// DECSTBM: `top`/`bottom` are 1-based, 0 meaning the default; an empty or inverted region is ignored. Homes the cursor.
    mutating func setScrollRegion(top newTop: Int, bottom newBottom: Int) {
        let first = (newTop == 0 ? 1 : newTop) - 1
        let last = (newBottom == 0 ? rows : min(newBottom, rows)) - 1
        guard first < last else { return }
        top = first
        bottom = last
        moveTo(row: 1, column: 1)
    }

    mutating func setTabStop() { tabStops[column] = true }

    mutating func clearTabStops(all: Bool) {
        if all {
            for index in tabStops.indices { tabStops[index] = false }
        } else {
            tabStops[column] = false
        }
    }
}
