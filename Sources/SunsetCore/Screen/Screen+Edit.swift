extension Screen {
    private mutating func blankCell() -> Cell { Cell(scalar: 0, width: .narrow, style: currentEraseID()) }

    /// Erases columns `from...to` of a row (inclusive), cutting no double-width character in half.
    mutating func eraseCells(row: Int, from: Int, to: Int) {
        guard from <= to else { return }
        clearWideEdges(row: row, from: from, to: to)
        grid.fill(row: row, from: from, to: to, with: blankCell())
        markDirty(row)
    }

    /// EL: 0 to the end of the line, 1 to the start (cursor included), 2 the whole line.
    mutating func eraseInLine(_ mode: Int) {
        switch mode {
            case 0: eraseCells(row: row, from: column, to: columns - 1)
            case 1: eraseCells(row: row, from: 0, to: column)
            case 2: eraseCells(row: row, from: 0, to: columns - 1)
            default: return
        }
        if mode != 1 { grid.setWrapped(row: row, false) }
    }

    /// ED: 0 from the cursor to the end of the screen, 1 from the start to the cursor, 2 everything. (3, the scrollback, is not kept yet.)
    mutating func eraseInDisplay(_ mode: Int) {
        switch mode {
            case 0:
                eraseCells(row: row, from: column, to: columns - 1)
                if row + 1 < rows { eraseRows(row + 1 ... rows - 1) }
            case 1:
                if row > 0 { eraseRows(0 ... row - 1) }
                eraseCells(row: row, from: 0, to: column)
            case 2:
                eraseRows(0 ... rows - 1)
            case 3:
                scrollback.removeAll()
                markDirty(0 ... rows - 1)
            default:
                return
        }
    }

    private mutating func eraseRows(_ range: ClosedRange<Int>) {
        let blank = blankCell()
        for target in range {
            grid.fill(row: target, from: 0, to: columns - 1, with: blank)
            grid.setWrapped(row: target, false)
        }
        markDirty(range)
    }

    /// ECH: erases `count` cells from the cursor without moving anything.
    mutating func eraseCharacters(_ count: Int) {
        eraseCells(row: row, from: column, to: min(columns - 1, column + count - 1))
    }

    /// ICH: inserts `count` blanks at the cursor, pushing the rest of the line right (what falls off the edge is lost).
    mutating func insertCells(_ count: Int) {
        let n = min(count, columns - column)
        guard n > 0 else { return }
        clearWideEdges(row: row, from: column, to: columns - 1)
        var index = columns - 1
        while index >= column + n {
            grid[row, index] = grid[row, index - n]
            index -= 1
        }
        let blank = blankCell()
        for target in column ..< column + n { grid[row, target] = blank }
        // The shift can leave the right half of a wide character at the edge without its left half.
        if grid[row, columns - 1].width == .wide { grid[row, columns - 1] = blank }
        markDirty(row)
    }

    /// DCH: deletes `count` cells at the cursor, pulling the rest of the line left.
    mutating func deleteCells(_ count: Int) {
        let n = min(count, columns - column)
        guard n > 0 else { return }
        clearWideEdges(row: row, from: column, to: column + n - 1)
        for index in column ..< columns - n { grid[row, index] = grid[row, index + n] }
        let blank = blankCell()
        for target in columns - n ..< columns { grid[row, target] = blank }
        if grid[row, column].width == .spacerTail { grid[row, column] = blank }
        markDirty(row)
    }

    /// IL: inserts blank lines at the cursor row, inside the scroll region only; the cursor goes to the first column.
    mutating func insertLines(_ count: Int) {
        guard row >= top, row <= bottom else { return }
        scrollDown(from: row, to: bottom, by: count)
        carriageReturn()
    }

    /// DL: deletes lines at the cursor row, inside the scroll region only; the cursor goes to the first column.
    mutating func deleteLines(_ count: Int) {
        guard row >= top, row <= bottom else { return }
        scrollUp(from: row, to: bottom, by: count)
        carriageReturn()
    }

    /// REP: repeats the last printed character.
    mutating func repeatLast(_ count: Int) {
        guard lastPrinted != 0, let scalar = Unicode.Scalar(lastPrinted) else { return }
        for _ in 0 ..< min(count, 65535) { putScalar(scalar) }
    }

    /// DECALN: the screen of `E`s used to check alignment; also resets the margins and homes the cursor.
    mutating func alignmentTest() {
        top = 0
        bottom = rows - 1
        let id = currentPenID()
        let cell = Cell(scalar: 0x45, width: .narrow, style: id)
        for target in 0 ..< rows {
            grid.fill(row: target, from: 0, to: columns - 1, with: cell)
            grid.setWrapped(row: target, false)
        }
        markDirty(0 ... rows - 1)
        moveTo(row: 1, column: 1)
    }
}
