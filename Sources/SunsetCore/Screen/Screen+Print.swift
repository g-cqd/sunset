import TerminalKitText

extension Screen {
    var activeCharset: Charset { shifted ? charsets.g1 : charsets.g0 }

    mutating func putASCII(_ byte: UInt8) { put(activeCharset.translate(byte), width: 1) }

    /// A run of printable ASCII written a row at a time: one dirty mark, one pass over the cells, the wide-character edges checked at the two ends only.
    mutating func putASCIIRun(_ run: Span<UInt8>) {
        guard activeCharset == .ascii else {
            for index in run.indices { putASCII(run[index]) }
            return
        }
        var index = 0
        let count = run.count
        while index < count {
            if pendingWrap {
                pendingWrap = false
                if modes.autoWrap { wrap() }
            }
            let take = min(columns - column, count - index)
            let id = currentPenID()
            clearWideEdges(row: row, from: column, to: column + take - 1)
            let start = grid.base(row) + column
            let first = index
            grid.cells.withUnsafeMutableBufferPointer { cells in
                for offset in 0 ..< take {
                    cells[start + offset] = Cell(scalar: UInt32(run[first + offset]), width: .narrow, style: id)
                }
            }
            lastPrinted = UInt32(run[index + take - 1])
            markDirty(row)
            index += take
            column += take
            if column >= columns {
                column = columns - 1
                pendingWrap = true
            }
        }
    }

    mutating func putScalar(_ scalar: Unicode.Scalar) {
        let width = UnicodeWidth.displayWidth(of: Character(scalar))
        put(scalar.value, width: width)
    }

    /// Writes one character at the cursor. Zero-width scalars (combining marks, joiners) are dropped for now: grapheme clusters are not modelled yet.
    mutating func put(_ scalar: UInt32, width: Int) {
        guard width > 0 else { return }
        if pendingWrap {
            pendingWrap = false
            if modes.autoWrap { wrap() }
        }
        if width == 2, column == columns - 1 {
            guard modes.autoWrap else { return }
            // No room for both halves: leave the last cell blank and continue on the next line.
            grid[row, column] = Cell(scalar: 0, width: .narrow, style: currentEraseID())
            wrap()
        }
        if modes.insert { insertCells(width) }
        let id = currentPenID()
        clearWideEdges(row: row, from: column, to: column + width - 1)
        if width == 2 {
            grid[row, column] = Cell(scalar: scalar, width: .wide, style: id)
            grid[row, column + 1] = Cell(scalar: 0, width: .spacerTail, style: id)
        } else {
            grid[row, column] = Cell(scalar: scalar, width: .narrow, style: id)
        }
        lastPrinted = scalar
        markDirty(row)
        column += width
        if column >= columns {
            column = columns - 1
            pendingWrap = true
        }
    }

    /// The line continues on the next row: mark it, return the carriage and move down (scrolling at the bottom of the region).
    mutating func wrap() {
        grid.wrapped[Int(grid.rowMap[row])] = true
        column = 0
        lineFeed()
    }

    /// If a range of cells cuts a double-width character at either edge, blanks the half that would be left alone.
    mutating func clearWideEdges(row: Int, from: Int, to: Int) {
        if from > 0, grid[row, from].width == .spacerTail {
            grid[row, from - 1] = Cell(scalar: 0, width: .narrow, style: grid[row, from - 1].styleID)
        }
        if to < columns - 1, grid[row, to].width == .wide {
            grid[row, to + 1] = Cell(scalar: 0, width: .narrow, style: grid[row, to + 1].styleID)
        }
    }
}
