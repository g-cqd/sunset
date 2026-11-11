/// The cells of one screen: rows are reached through a row map, so scrolling moves row numbers, not cells.
struct Grid: Sendable {
    let columns: Int
    let rows: Int
    var cells: ContiguousArray<Cell>
    /// Physical row of each screen row.
    var rowMap: ContiguousArray<Int32>
    /// By physical row: the line continues on the next (the text wrapped rather than ended).
    var wrapped: ContiguousArray<Bool>
    /// By physical row: every cell at or past this column is the empty cell (raw 0). An upper bound, kept by the subscript and `fill`; code that writes
    /// `cells` directly calls `noteWritten` or `recountUsed`. It lets blanking a row and saving it to the history cost what the row holds, not its width (a
    /// line of one character was 120 cells blanked and 120 scanned: a quarter of a scrolling flood, renderer plan's comparison of 2026-11-09).
    var used: ContiguousArray<Int32>

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        cells = ContiguousArray(repeating: .empty, count: columns * rows)
        rowMap = ContiguousArray((0 ..< rows).map { Int32($0) })
        wrapped = ContiguousArray(repeating: false, count: rows)
        used = ContiguousArray(repeating: 0, count: rows)
    }

    @inline(__always) func base(_ row: Int) -> Int { Int(rowMap[row]) * columns }

    @inline(__always) subscript(row: Int, column: Int) -> Cell {
        get { cells[base(row) + column] }
        set {
            let physical = Int(rowMap[row])
            cells[physical * columns + column] = newValue
            if newValue.raw != 0, used[physical] <= column { used[physical] = Int32(column + 1) }
        }
    }

    /// How many leading cells of `row` can be other than empty (the cells past them are).
    @inline(__always) func usedCount(row: Int) -> Int { Int(used[Int(rowMap[row])]) }

    /// Cells `from...to` of `row` were written directly, not through the subscript.
    @inline(__always) mutating func noteWritten(row: Int, through column: Int) {
        let physical = Int(rowMap[row])
        if used[physical] <= column { used[physical] = Int32(column + 1) }
    }

    /// Fills `from...to` of `row` with `cell`. An empty cell only needs writing below the row's used count, and moves the count down when it reaches it.
    mutating func fill(row: Int, from: Int, to: Int, with cell: Cell) {
        guard from <= to else { return }
        let physical = Int(rowMap[row])
        var last = to
        if cell.raw == 0 {
            let count = used[physical]
            last = min(to, Int(count) - 1)
            // Written only when it moves: a row that holds nothing is blanked without touching anything.
            if to + 1 >= count, count > from { used[physical] = Int32(from) }
        } else if used[physical] <= to {
            used[physical] = Int32(to + 1)
        }
        guard from <= last else { return }
        let start = physical * columns
        cells.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            unsafe (base + start + from).update(repeating: cell, count: last - from + 1)
        }
    }

    /// Works the used counts out from the cells (after writing `cells` directly).
    mutating func recountUsed() {
        for physical in 0 ..< rows {
            let start = physical * columns
            let count = cells.withUnsafeBufferPointer {
                CellKernels.usedLength(UnsafeBufferPointer(rebasing: $0[start ..< start + columns]))
            }
            used[physical] = Int32(count)
        }
    }
}
