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
            lastHead = (row, column + take - 1)
            joinable = true
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
        let width = ScalarWidth.of(scalar)
        if joinable, mayJoin(scalar, width: width), join(scalar) { return }
        afterJoiner = false
        put(scalar.value, width: width)
    }

    /// Cheap test before the real one: only zero-width scalars (marks, joiners, selectors), regional indicators, emoji modifiers, Hangul vowels and
    /// finals, and a scalar right after a joiner can extend the cluster before them. Everything else (letters, CJK) starts its own cell without any
    /// allocation.
    private func mayJoin(_ scalar: Unicode.Scalar, width: Int) -> Bool {
        if width == 0 || afterJoiner { return true }
        switch scalar.value {
            case 0x1F1E6 ... 0x1F1FF, 0x1F3FB ... 0x1F3FF, 0x1160 ... 0x11FF, 0xD7B0 ... 0xD7FF: return true
            default: return false
        }
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
            grid[row, column] = Cell(scalar: 0, width: .spacerHead, style: currentEraseID())
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
        lastHead = (row, column)
        joinable = true
        markDirty(row)
        column += width
        if column >= columns {
            column = columns - 1
            pendingWrap = true
        }
    }

    /// Tries to make `scalar` part of the grapheme cluster of the cell written last. True when it was absorbed (or dropped as a mark that cannot be
    /// kept); false when it starts a cluster of its own. The test is the standard's: the scalars so far plus this one are a single `Character`.
    mutating func join(_ scalar: Unicode.Scalar) -> Bool {
        let (headRow, headColumn) = lastHead
        guard headRow < rows, headColumn < columns else { return false }
        let head = grid[headRow, headColumn]
        guard head.width != .spacerTail, head.width != .spacerHead, head.scalar != 0 else { return false }
        var cluster = ContiguousArray<UInt32>()
        if head.isCluster {
            cluster.append(contentsOf: clusters.scalars(of: head.scalar))
        } else {
            cluster.append(head.scalar)
        }
        cluster.append(scalar.value)
        var view = String.UnicodeScalarView()
        for value in cluster { view.append(Unicode.Scalar(value) ?? "\u{FFFD}") }
        let text = String(view)
        guard text.count == 1, let character = text.first else { return false }
        guard let id = clusters.intern(cluster) else {
            // Table full: a mark is dropped, anything else starts a cell of its own.
            return ScalarWidth.of(scalar) == 0
        }
        var width = head.width
        if width == .narrow, UnicodeWidth.displayWidth(of: character) == 2, headColumn + 1 < columns {
            // The cluster has become double-width (an emoji presentation selector, a flag): it takes the next cell too.
            width = .wide
            clearWideEdges(row: headRow, from: headColumn + 1, to: headColumn + 1)
            grid[headRow, headColumn + 1] = Cell(scalar: 0, width: .spacerTail, style: head.styleID)
            if headRow == row, column == headColumn + 1, !pendingWrap {
                column += 1
                if column >= columns {
                    column = columns - 1
                    pendingWrap = true
                }
            }
        }
        grid[headRow, headColumn] = Cell(cluster: id, width: width, style: head.styleID)
        afterJoiner = scalar.value == 0x200D
        markDirty(headRow)
        return true
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
