extension Screen {
    /// A grid cut or padded to a new size without re-wrapping (the alternate screen).
    private func cutOrPad(_ source: Grid, columns newColumns: Int, rows newRows: Int) -> Grid {
        var result = Grid(columns: newColumns, rows: newRows)
        for target in 0 ..< min(source.rows, newRows) {
            for column in 0 ..< min(source.columns, newColumns) { result[target, column] = source[target, column] }
            if newColumns < source.columns, result[target, newColumns - 1].width == .wide {
                result[target, newColumns - 1] = Cell(
                    scalar: 0,
                    width: .narrow,
                    style: result[target, newColumns - 1].styleID
                )
            }
        }
        return result
    }

    /// Changes the size. The primary screen and its history are re-wrapped (`Reflow`); the alternate screen is cut or padded. The scroll region is
    /// reset, the cursors are kept inside, and every row is marked dirty.
    mutating func resize(columns newColumns: Int, rows newRows: Int) {
        guard newColumns > 0, newRows > 0, newColumns != columns || newRows != rows else { return }
        // Which grid is the primary one, and where its cursor is: the live cursor, or the one saved when the alternate screen was entered.
        let primary = isAlternate ? other : grid
        let primaryCursor = isAlternate ? (savedBeforeAlternate.map { ($0.row, $0.column) } ?? (0, 0)) : (row, column)
        var reflow = Reflow(
            grid: primary,
            scrollback: scrollback,
            cursorRow: primaryCursor.0,
            cursorColumn: primaryCursor.1,
            newColumns: newColumns,
            newRows: newRows,
            limit: scrollback.limit
        )
        let result = reflow.run()
        let evicted = scrollback.evicted
        scrollback = result.scrollback
        scrollback.evicted = evicted
        if isAlternate {
            other = result.grid
            grid = cutOrPad(grid, columns: newColumns, rows: newRows)
            savedBeforeAlternate?.row = result.cursorRow
            savedBeforeAlternate?.column = result.cursorColumn
            row = min(row, newRows - 1)
            column = min(column, newColumns - 1)
        } else {
            grid = result.grid
            other = cutOrPad(other, columns: newColumns, rows: newRows)
            row = result.cursorRow
            column = result.cursorColumn
        }
        var stops = Screen.defaultTabStops(newColumns)
        for index in 0 ..< min(newColumns, columns) { stops[index] = tabStops[index] }
        tabStops = stops
        columns = newColumns
        rows = newRows
        top = 0
        bottom = newRows - 1
        pendingWrap = false
        joinable = false
        if var state = saved {
            state.row = min(state.row, newRows - 1)
            state.column = min(state.column, newColumns - 1)
            saved = state
        }
        dirtyRows = ContiguousArray(repeating: true, count: newRows)
        generation &+= 1
    }
}
