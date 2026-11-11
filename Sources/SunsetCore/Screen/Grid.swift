/// The cells of one screen: rows are reached through a row map, so scrolling moves row numbers, not cells.
///
/// What is kept for each row is in one array, `meta`, in three parts of `rows` numbers each, so that an operation that touches several of them (a scroll:
/// the map, the count and the wrap of the row that arrives) pays for one uniqueness check, not one per array (measured 2026-11-11: about eight checks a
/// line were a tenth of a scrolling flood):
///
/// - `meta[row]`: the physical row of screen row `row` (the row map);
/// - `meta[rows + physical]`: the used count of a physical row: every cell at or past this column is the empty cell (raw 0). An upper bound, kept by the
///   subscript, `fill` and `scroll`; code that writes `cells` directly calls `noteWritten` or `recountUsed`. It lets blanking a row and saving it to the
///   history cost what the row holds, not its width;
/// - `meta[2 * rows + physical]`: 1 when the line continues on the next row (the text wrapped rather than ended).
struct Grid: Sendable {
    let columns: Int
    let rows: Int
    var cells: ContiguousArray<Cell>
    var meta: ContiguousArray<Int32>

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        cells = ContiguousArray(repeating: .empty, count: columns * rows)
        meta = ContiguousArray(repeating: 0, count: rows * 3)
        for row in 0 ..< rows { meta[row] = Int32(row) }
    }

    /// The physical row of a screen row.
    @inline(__always) func physical(_ row: Int) -> Int { Int(meta[row]) }

    @inline(__always) func base(_ row: Int) -> Int { physical(row) * columns }

    /// How many leading cells of a physical row can be other than empty.
    @inline(__always) func used(physical: Int) -> Int { Int(meta[rows + physical]) }

    /// How many leading cells of `row` can be other than empty (the cells past them are).
    @inline(__always) func usedCount(row: Int) -> Int { used(physical: physical(row)) }

    @inline(__always) func isWrapped(row: Int) -> Bool { meta[2 * rows + physical(row)] != 0 }

    /// Written only when it changes: most rows are not wrapped and stay so.
    @inline(__always) mutating func setWrapped(row: Int, _ wrapped: Bool) {
        let index = 2 * rows + physical(row)
        let value: Int32 = wrapped ? 1 : 0
        if meta[index] != value { meta[index] = value }
    }

    @inline(__always) subscript(row: Int, column: Int) -> Cell {
        get { cells[base(row) + column] }
        set {
            let physical = physical(row)
            cells[physical * columns + column] = newValue
            if newValue.raw != 0, meta[rows + physical] <= column { meta[rows + physical] = Int32(column + 1) }
        }
    }

    /// Cells up to `column` of `row` were written directly, not through the subscript.
    @inline(__always) mutating func noteWritten(row: Int, through column: Int) {
        let index = rows + physical(row)
        if meta[index] <= column { meta[index] = Int32(column + 1) }
    }

    /// Fills `from...to` of `row` with `cell`. An empty cell only needs writing below the row's used count, and moves the count down when it reaches it.
    mutating func fill(row: Int, from: Int, to: Int, with cell: Cell) {
        guard from <= to else { return }
        let physical = physical(row)
        let count = meta[rows + physical]
        var last = to
        if cell.raw == 0 {
            last = min(to, Int(count) - 1)
            // Written only when it moves: a row that holds nothing is blanked without touching anything.
            if to + 1 >= count, count > from { meta[rows + physical] = Int32(from) }
        } else if count <= to {
            meta[rows + physical] = Int32(to + 1)
        }
        guard from <= last else { return }
        fillCells(physical: physical, from: from, count: last - from + 1, with: cell)
    }

    @inline(__always) mutating func fillCells(physical: Int, from: Int, count: Int, with cell: Cell) {
        let start = physical * columns + from
        cells.withUnsafeMutableBufferPointer { buffer in
            for index in start ..< start + count { buffer[index] = cell }
        }
    }

    /// Works the used counts out from the cells (after writing `cells` directly).
    mutating func recountUsed() {
        for physical in 0 ..< rows {
            let start = physical * columns
            let count = cells.withUnsafeBufferPointer {
                CellKernels.usedLength(UnsafeBufferPointer(rebasing: $0[start ..< start + columns]))
            }
            meta[rows + physical] = Int32(count)
        }
    }
}
