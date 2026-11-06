/// The cells of one screen: rows are reached through a row map, so scrolling moves row numbers, not cells.
struct Grid: Sendable {
    let columns: Int
    let rows: Int
    var cells: ContiguousArray<Cell>
    /// Physical row of each screen row.
    var rowMap: ContiguousArray<Int32>
    /// By physical row: the line continues on the next (the text wrapped rather than ended).
    var wrapped: ContiguousArray<Bool>

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        cells = ContiguousArray(repeating: .empty, count: columns * rows)
        rowMap = ContiguousArray((0 ..< rows).map { Int32($0) })
        wrapped = ContiguousArray(repeating: false, count: rows)
    }

    @inline(__always) func base(_ row: Int) -> Int { Int(rowMap[row]) * columns }

    @inline(__always) subscript(row: Int, column: Int) -> Cell {
        get { cells[base(row) + column] }
        set { cells[base(row) + column] = newValue }
    }

    mutating func fill(row: Int, from: Int, to: Int, with cell: Cell) {
        guard from <= to else { return }
        let start = base(row)
        for index in start + from ... start + to { cells[index] = cell }
    }
}
