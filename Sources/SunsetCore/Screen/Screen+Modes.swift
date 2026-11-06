extension Screen {
    /// SM/RM without a marker: 4 insert mode, 20 line-feed/new-line mode. Others are ignored.
    mutating func setANSIMode(_ mode: Int, enabled: Bool) {
        switch mode {
            case 4: insertMode = enabled
            case 20: newLineMode = enabled
            default: break
        }
    }

    /// DECSET/DECRST (`CSI ? Pm h/l`).
    mutating func setPrivateMode(_ mode: Int, enabled: Bool) {
        switch mode {
            case 6:
                originMode = enabled
                moveTo(row: 1, column: 1)
            case 7: autoWrap = enabled
            case 25: cursorVisible = enabled
            case 47:
                enabled
                    ? enterAlternate(saveCursor: false, clear: false)
                    : leaveAlternate(restoreCursor: false, clear: false)
            case 1047:
                enabled
                    ? enterAlternate(saveCursor: false, clear: false)
                    : leaveAlternate(restoreCursor: false, clear: true)
            case 1049:
                enabled
                    ? enterAlternate(saveCursor: true, clear: true) : leaveAlternate(restoreCursor: true, clear: false)
            default: break
        }
    }

    mutating func enterAlternate(saveCursor save: Bool, clear: Bool) {
        guard !isAlternate else { return }
        if save { savedBeforeAlternate = currentCursor() }
        swap(&grid, &other)
        isAlternate = true
        if clear { clearGrid() }
        markDirty(0 ... rows - 1)
    }

    mutating func leaveAlternate(restoreCursor restore: Bool, clear: Bool) {
        guard isAlternate else { return }
        if clear { clearGrid() }
        swap(&grid, &other)
        isAlternate = false
        if restore, let state = savedBeforeAlternate {
            column = min(state.column, columns - 1)
            row = min(state.row, rows - 1)
            pendingWrap = state.pendingWrap
            pen = state.pen
            originMode = state.originMode
            penChanged()
        }
        markDirty(0 ... rows - 1)
    }

    private func currentCursor() -> SavedCursor {
        SavedCursor(column: column, row: row, pendingWrap: pendingWrap, pen: pen, originMode: originMode)
    }

    private mutating func clearGrid() {
        let blank = Cell(scalar: 0, width: .narrow, style: 0)
        for target in 0 ..< rows {
            grid.fill(row: target, from: 0, to: columns - 1, with: blank)
            grid.wrapped[Int(grid.rowMap[target])] = false
        }
    }

    /// RIS: back to the state of a new screen of the same size.
    mutating func fullReset() {
        self = Screen(columns: columns, rows: rows)
    }
}
