extension Screen {
    /// The most reply bytes kept waiting; a program that asks faster than the host writes loses the surplus (counted in `droppedReplies`).
    static let replyLimit = 65536

    mutating func reply(_ build: (inout ReplyWriter) -> Void) {
        var writer = ReplyWriter()
        build(&writer)
        guard !writer.overflowed, replies.count + writer.count <= Self.replyLimit else {
            droppedReplies += 1
            return
        }
        for index in 0 ..< writer.count { replies.append(writer.storage[index]) }
    }

    mutating func takeReplies() -> [UInt8] {
        let taken = Array(replies)
        replies.removeAll(keepingCapacity: true)
        return taken
    }

    mutating func reportDeviceAttributes() {
        reply { $0.text("\u{1B}[?62;22c") }
    }

    mutating func reportSecondaryDeviceAttributes() {
        reply { $0.text("\u{1B}[>1;10;0c") }
    }

    mutating func reportVersion() {
        reply { writer in
            writer.text("\u{1B}P>|sunset(")
            writer.text("0.0.1")
            writer.text(")\u{1B}\\")
        }
    }

    mutating func reportStatus() {
        reply { $0.text("\u{1B}[0n") }
    }

    /// CPR: 1-based, relative to the scroll region in origin mode. `private` is DECXCPR (`CSI ? r ; c R`).
    mutating func reportCursorPosition(private isPrivate: Bool) {
        let line = (modes.origin ? row - top : row) + 1
        let place = column + 1
        reply { writer in
            writer.text(isPrivate ? "\u{1B}[?" : "\u{1B}[")
            writer.number(line)
            writer.byte(0x3B)
            writer.number(place)
            // DECXCPR also names the page (always the first).
            if isPrivate { writer.text(";1") }
            writer.byte(0x52)
        }
    }

    mutating func reportSize() {
        let height = rows
        let width = columns
        reply { writer in
            writer.text("\u{1B}[8;")
            writer.number(height)
            writer.byte(0x3B)
            writer.number(width)
            writer.byte(0x74)
        }
    }

    /// DECRQM answer: `CSI [?] mode ; state $ y`.
    mutating func reportMode(_ mode: Int, private isPrivate: Bool) {
        let state = modeState(mode, private: isPrivate)
        reply { writer in
            writer.text(isPrivate ? "\u{1B}[?" : "\u{1B}[")
            writer.number(mode)
            writer.byte(0x3B)
            writer.number(state)
            writer.text("$y")
        }
    }

    /// 0 not recognised, 1 set, 2 reset, 4 permanently reset.
    func modeState(_ mode: Int, private isPrivate: Bool) -> Int {
        func flag(_ value: Bool) -> Int { value ? 1 : 2 }
        if !isPrivate {
            switch mode {
                case 4: return flag(modes.insert)
                case 20: return flag(modes.newLine)
                default: return 0
            }
        }
        switch mode {
            case 1: return flag(modes.applicationCursorKeys)
            case 3: return 4
            case 5: return flag(modes.reverseVideo)
            case 6: return flag(modes.origin)
            case 7: return flag(modes.autoWrap)
            case 9: return flag(modes.mouseTracking == .x10)
            case 12: return flag(cursorBlinks)
            case 25: return flag(modes.cursorVisible)
            case 47, 1047, 1049: return flag(isAlternate)
            case 1000: return flag(modes.mouseTracking == .normal)
            case 1002: return flag(modes.mouseTracking == .button)
            case 1003: return flag(modes.mouseTracking == .any)
            case 1004: return flag(modes.focusEvents)
            case 1005: return flag(modes.mouseFormat == .utf8)
            case 1006: return flag(modes.mouseFormat == .sgr)
            case 1007: return flag(modes.alternateScroll)
            case 1015: return flag(modes.mouseFormat == .urxvt)
            case 1016: return flag(modes.mouseFormat == .sgrPixels)
            case 2004: return flag(modes.bracketedPaste)
            case 2026: return flag(modes.synchronizedOutput)
            default: return 0
        }
    }
}
