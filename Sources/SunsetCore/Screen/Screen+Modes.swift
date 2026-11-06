extension Screen {
    /// SM/RM without a marker: 4 insert mode, 20 line-feed/new-line mode. Others are ignored.
    mutating func setANSIMode(_ mode: Int, enabled: Bool) {
        switch mode {
            case 4: modes.insert = enabled
            case 20: modes.newLine = enabled
            default: break
        }
    }

    /// DECSET/DECRST (`CSI ? Pm h/l`). Modes this screen does not implement are ignored (and DECRQM reports them as not recognised).
    mutating func setPrivateMode(_ mode: Int, enabled: Bool) {
        switch mode {
            case 1: modes.applicationCursorKeys = enabled
            case 5:
                modes.reverseVideo = enabled
                markDirty(0 ... rows - 1)
            case 6:
                modes.origin = enabled
                moveTo(row: 1, column: 1)
            case 7: modes.autoWrap = enabled
            case 12: cursorBlinks = enabled
            case 25: modes.cursorVisible = enabled
            case 9: setTracking(.x10, enabled)
            case 1000: setTracking(.normal, enabled)
            case 1002: setTracking(.button, enabled)
            case 1003: setTracking(.any, enabled)
            case 1004: modes.focusEvents = enabled
            case 1005: setFormat(.utf8, enabled)
            case 1006: setFormat(.sgr, enabled)
            case 1015: setFormat(.urxvt, enabled)
            case 1016: setFormat(.sgrPixels, enabled)
            case 1007: modes.alternateScroll = enabled
            case 2004: modes.bracketedPaste = enabled
            case 2026: modes.synchronizedOutput = enabled
            case 47: setAlternate(enabled, saveCursor: false, clearOnEnter: false, clearOnLeave: false)
            case 1047: setAlternate(enabled, saveCursor: false, clearOnEnter: false, clearOnLeave: true)
            case 1049: setAlternate(enabled, saveCursor: true, clearOnEnter: true, clearOnLeave: false)
            default: break
        }
    }

    private mutating func setTracking(_ level: MouseTracking, _ enabled: Bool) {
        if enabled {
            modes.mouseTracking = level
        } else if modes.mouseTracking == level {
            modes.mouseTracking = .none
        }
    }

    private mutating func setFormat(_ format: MouseFormat, _ enabled: Bool) {
        if enabled {
            modes.mouseFormat = format
        } else if modes.mouseFormat == format {
            modes.mouseFormat = .x10
        }
    }

    private mutating func setAlternate(_ enabled: Bool, saveCursor: Bool, clearOnEnter: Bool, clearOnLeave: Bool) {
        if enabled {
            enterAlternate(saveCursor: saveCursor, clear: clearOnEnter)
        } else {
            leaveAlternate(restoreCursor: saveCursor, clear: clearOnLeave)
        }
    }

    mutating func enterAlternate(saveCursor save: Bool, clear: Bool) {
        guard !isAlternate else { return }
        if save { savedBeforeAlternate = currentCursor() }
        swap(&grid, &other)
        swap(&keyboard, &otherKeyboard)
        isAlternate = true
        if clear { clearGrid() }
        markDirty(0 ... rows - 1)
    }

    mutating func leaveAlternate(restoreCursor restore: Bool, clear: Bool) {
        guard isAlternate else { return }
        if clear { clearGrid() }
        swap(&grid, &other)
        swap(&keyboard, &otherKeyboard)
        isAlternate = false
        if restore, let state = savedBeforeAlternate {
            column = min(state.column, columns - 1)
            row = min(state.row, rows - 1)
            pendingWrap = state.pendingWrap
            pen = state.pen
            modes.origin = state.originMode
            charsets = state.charsets
            shifted = state.shifted
            penChanged()
        }
        markDirty(0 ... rows - 1)
    }

    private func currentCursor() -> SavedCursor {
        SavedCursor(
            column: column,
            row: row,
            pendingWrap: pendingWrap,
            pen: pen,
            originMode: modes.origin,
            charsets: charsets,
            shifted: shifted
        )
    }

    private mutating func clearGrid() {
        let blank = Cell(scalar: 0, width: .narrow, style: 0)
        for target in 0 ..< rows {
            grid.fill(row: target, from: 0, to: columns - 1, with: blank)
            grid.wrapped[Int(grid.rowMap[target])] = false
        }
    }

    /// `CSI Ps t`: 18 reports the size in characters, 22 and 23 save and restore the title. Everything else (moving, resizing, iconifying, reports of
    /// the title or position) is refused, so a program cannot reach the window or read it back (ADR-0026).
    mutating func windowOperation(_ parameters: Parameters) {
        switch parameters[0] {
            case 18: reportSize()
            case 22 where parameters[1] == 0 || parameters[1] == 2: pushTitle()
            case 23 where parameters[1] == 0 || parameters[1] == 2: popTitle()
            default: break
        }
    }

    /// DSR: 5 asks whether the terminal is working (always "ok"), 6 asks for the cursor position.
    mutating func deviceStatus(_ request: Int, private isPrivate: Bool) {
        switch request {
            case 5 where !isPrivate: reportStatus()
            case 6: reportCursorPosition(private: isPrivate)
            default: break
        }
    }

    /// DECSCUSR: 0 and 1 blinking block, 2 steady block, 3/4 underline, 5/6 bar; other values change nothing.
    mutating func setCursorStyle(_ style: Int) {
        switch style {
            case 0, 1: (cursorShape, cursorBlinks) = (.block, true)
            case 2: (cursorShape, cursorBlinks) = (.block, false)
            case 3: (cursorShape, cursorBlinks) = (.underline, true)
            case 4: (cursorShape, cursorBlinks) = (.underline, false)
            case 5: (cursorShape, cursorBlinks) = (.bar, true)
            case 6: (cursorShape, cursorBlinks) = (.bar, false)
            default: break
        }
    }

    /// DECSTR: modes, pen, margins, saved cursor and cursor style go back to their defaults; the text stays.
    mutating func softReset() {
        modes = Modes()
        pen = CellStyle()
        penChanged()
        top = 0
        bottom = rows - 1
        saved = nil
        pendingWrap = false
        charsets = (.ascii, .ascii)
        shifted = false
        cursorShape = .block
        cursorBlinks = true
    }

    /// RIS: back to the state of a new screen of the same size.
    mutating func fullReset() {
        self = Screen(columns: columns, rows: rows)
    }
}
