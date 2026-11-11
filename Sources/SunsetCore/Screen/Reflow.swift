/// Re-wraps the primary screen and its history for a new size. Lines that wrapped are joined into logical lines and split again at the new width; the
/// cursor and the top of the screen are followed through the change. Pure: the screen hands in its pieces and takes the new ones back.
struct Reflow {
    struct Result {
        var grid: Grid
        var scrollback: Scrollback
        var cursorRow: Int
        var cursorColumn: Int
    }

    let grid: Grid
    let scrollback: Scrollback
    let cursorRow: Int
    let cursorColumn: Int
    let newColumns: Int
    let newRows: Int
    let limit: Int

    // The old buffer as logical lines: cells joined, where each starts, and where the two followed positions fall.
    private var cells: [Cell] = []
    private var lineStarts: [Int] = []
    private var cursorIndex = 0
    private var topIndex = 0

    init(
        grid: Grid,
        scrollback: Scrollback,
        cursorRow: Int,
        cursorColumn: Int,
        newColumns: Int,
        newRows: Int,
        limit: Int
    ) {
        self.grid = grid
        self.scrollback = scrollback
        self.cursorRow = cursorRow
        self.cursorColumn = cursorColumn
        self.newColumns = newColumns
        self.newRows = newRows
        self.limit = limit
    }

    private static func isBlank(_ cell: Cell) -> Bool {
        cell.scalar == 0 && cell.styleID == 0 && cell.width != .wide && cell.width != .spacerTail
    }

    mutating func run() -> Result {
        collect()
        // Rows of the new buffer: cells newColumns wide, whether each wrapped, and where the followed positions landed.
        var rows: [Cell] = []
        var wrapped: [Bool] = []
        var newCursor = (row: 0, column: 0)
        var newTop = 0
        for line in lineStarts.indices {
            let from = lineStarts[line]
            let to = line + 1 < lineStarts.count ? lineStarts[line + 1] : cells.count
            place(line: from ..< to, into: &rows, wrapped: &wrapped, cursor: &newCursor, top: &newTop)
        }
        return assemble(rows: rows, wrapped: wrapped, cursor: newCursor, top: newTop)
    }

    /// Joins the old rows into logical lines (history first, then the screen), noting where the cursor and the top of the screen are.
    private mutating func collect() {
        let history = scrollback.count
        let total = history + grid.rows
        var lineOpen = false
        for index in 0 ..< total {
            let onScreen = index >= history
            let screenRow = index - history
            if !lineOpen {
                lineStarts.append(cells.count)
            }
            if onScreen, screenRow == 0 { topIndex = cells.count }
            for column in 0 ..< grid.columns {
                let cell = onScreen ? grid[screenRow, column] : scrollback[index, column]
                if onScreen, screenRow == cursorRow, column == cursorColumn { cursorIndex = cells.count }
                if cell.width == .spacerHead { continue }
                cells.append(cell)
            }
            let continues = onScreen ? grid.isWrapped(row: screenRow) : scrollback.isWrapped(index)
            lineOpen = continues && index + 1 < total
        }
    }

    /// Splits one logical line into rows of the new width.
    private func place(
        line range: Range<Int>,
        into rows: inout [Cell],
        wrapped: inout [Bool],
        cursor: inout (row: Int, column: Int),
        top: inout Int
    ) {
        // Trailing blanks go, except those the cursor sits in.
        var end = range.upperBound
        let keep =
            cursorIndex >= range.lowerBound && cursorIndex < range.upperBound ? cursorIndex + 1 : range.lowerBound
        while end > max(range.lowerBound, keep), Self.isBlank(cells[end - 1]) { end -= 1 }
        let firstRow = wrapped.count
        var column = 0
        func startRow() {
            rows.append(contentsOf: repeatElement(Cell.empty, count: newColumns))
            wrapped.append(false)
        }
        startRow()
        var index = range.lowerBound
        while index < end {
            let cell = cells[index]
            let width = cell.width == .wide ? 2 : 1
            if width == 2, newColumns == 1 {
                // A double-width character cannot fit at all: it is dropped.
                index += 2
                continue
            }
            if column + width > newColumns {
                if width == 2, column < newColumns {
                    rows[(wrapped.count - 1) * newColumns + column] = Cell(
                        scalar: 0,
                        width: .spacerHead,
                        style: cell.styleID
                    )
                }
                wrapped[wrapped.count - 1] = true
                startRow()
                column = 0
            }
            if index == cursorIndex { cursor = (wrapped.count - 1, column) }
            if index == topIndex { top = wrapped.count - 1 }
            let base = (wrapped.count - 1) * newColumns + column
            rows[base] = cell
            if width == 2, index + 1 < end { rows[base + 1] = cells[index + 1] }
            column += width
            index += width
        }
        // Followed positions at or past the end of the (trimmed) line.
        if cursorIndex >= end, cursorIndex >= range.lowerBound, cursorIndex < range.upperBound {
            cursor = (wrapped.count - 1, min(column, newColumns - 1))
        }
        if topIndex >= end, topIndex >= range.lowerBound, topIndex < range.upperBound || topIndex == cells.count {
            top = wrapped.count - 1
        }
        _ = firstRow
    }

    /// Chooses which new rows are the screen and which are history.
    private func assemble(rows: [Cell], wrapped: [Bool], cursor: (row: Int, column: Int), top markerTop: Int) -> Result
    {
        func rowIsBlank(_ row: Int) -> Bool {
            !wrapped[row] && rows[row * newColumns ..< (row + 1) * newColumns].allSatisfy(Self.isBlank)
        }
        var total = wrapped.count
        // Blank rows below the cursor are not content.
        while total > cursor.row + 1, rowIsBlank(total - 1) { total -= 1 }
        var top = markerTop
        if cursor.row >= top + newRows { top = cursor.row - newRows + 1 }
        // The cursor was on the last row and there is room below the content: take history back to fill the screen.
        if cursorRow == grid.rows - 1, top + newRows > total, top > 0 { top = max(0, total - newRows) }
        top = min(top, cursor.row)

        var newGrid = Grid(columns: newColumns, rows: newRows)
        for row in 0 ..< newRows where top + row < total {
            let source = (top + row) * newColumns
            let base = newGrid.base(row)
            for column in 0 ..< newColumns { newGrid.cells[base + column] = rows[source + column] }
            newGrid.setWrapped(row: row, wrapped[top + row])
        }
        newGrid.recountUsed()
        var history = Scrollback(columns: newColumns, limit: limit)
        for row in max(0, top - limit) ..< top {
            history.push(rows[row * newColumns ..< (row + 1) * newColumns], wrapped: wrapped[row])
        }
        return Result(grid: newGrid, scrollback: history, cursorRow: cursor.row - top, cursorColumn: cursor.column)
    }
}
