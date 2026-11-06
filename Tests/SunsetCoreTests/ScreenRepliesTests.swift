import Testing

@testable import SunsetCore

private let esc = "\u{1B}"

/// Feeds `input` and returns what the terminal answered.
private func answer(_ input: String, _ columns: Int = 10, _ rows: Int = 4) -> String {
    var terminal = Terminal(columns: columns, rows: rows)
    terminal.feed(input)
    return String(decoding: terminal.takeReplies(), as: UTF8.self)
}

private func screen(_ input: String, _ columns: Int = 10, _ rows: Int = 4) -> Screen {
    var terminal = Terminal(columns: columns, rows: rows)
    terminal.feed(input)
    return terminal.screen
}

@Suite("Replies") struct ScreenRepliesTests {
    @Test func `primary and secondary device attributes`() {
        #expect(answer("\(esc)[c") == "\(esc)[?62;22c")
        #expect(answer("\(esc)[0c") == "\(esc)[?62;22c")
        #expect(answer("\(esc)[1c") == "")
        #expect(answer("\(esc)[>c") == "\(esc)[>1;10;0c")
        #expect(answer("\(esc)[>0c") == "\(esc)[>1;10;0c")
    }

    @Test func `device status and cursor position reports`() {
        #expect(answer("\(esc)[5n") == "\(esc)[0n")
        #expect(answer("\(esc)[6n") == "\(esc)[1;1R")
        #expect(answer("\(esc)[3;5H\(esc)[6n") == "\(esc)[3;5R")
        #expect(answer("\(esc)[?6n") == "\(esc)[?1;1;1R")
        #expect(answer("\(esc)[7n") == "")
        #expect(answer("0123456789\(esc)[6n") == "\(esc)[1;10R", "a pending wrap reports the last column")
    }

    @Test func `the cursor position is relative to the region in origin mode`() {
        #expect(answer("\(esc)[2;3r\(esc)[?6h\(esc)[1;1H\(esc)[6n") == "\(esc)[1;1R")
        #expect(answer("\(esc)[2;3r\(esc)[?6h\(esc)[2;1H\(esc)[6n") == "\(esc)[2;1R")
    }

    @Test func `window size in characters`() {
        #expect(answer("\(esc)[18t", 10, 4) == "\(esc)[8;4;10t")
    }

    @Test func `mode queries report set, reset and unknown modes`() {
        #expect(answer("\(esc)[?7$p") == "\(esc)[?7;1$y")
        #expect(answer("\(esc)[?7l\(esc)[?7$p") == "\(esc)[?7;2$y")
        #expect(answer("\(esc)[?9999$p") == "\(esc)[?9999;0$y")
        #expect(answer("\(esc)[4$p") == "\(esc)[4;2$y")
        #expect(answer("\(esc)[4h\(esc)[4$p") == "\(esc)[4;1$y")
        #expect(answer("\(esc)[?25$p") == "\(esc)[?25;1$y")
        #expect(answer("\(esc)[?1049$p") == "\(esc)[?1049;2$y")
        #expect(answer("\(esc)[?1049h\(esc)[?1049$p") == "\(esc)[?1049;1$y")
        #expect(answer("\(esc)[?3$p") == "\(esc)[?3;4$y", "DECCOLM is permanently reset: we never resize on request")
        #expect(answer("\(esc)[?2026h\(esc)[?2026$p") == "\(esc)[?2026;1$y")
        #expect(answer("\(esc)[?2004$p") == "\(esc)[?2004;2$y")
    }

    @Test func `cursor blinking is one state for mode 12 and DECSCUSR`() {
        #expect(answer("\(esc)[?12$p") == "\(esc)[?12;1$y")
        #expect(answer("\(esc)[?12l\(esc)[?12$p") == "\(esc)[?12;2$y")
        #expect(answer("\(esc)[2 q\(esc)[?12$p") == "\(esc)[?12;2$y")
        #expect(answer("\(esc)[2 q\(esc)[?12h\(esc)[?12$p") == "\(esc)[?12;1$y")
        #expect(answer("\(esc)[?12l\(esc)[5 q\(esc)[?12$p") == "\(esc)[?12;1$y")
    }

    @Test func `terminal name and version`() {
        #expect(answer("\(esc)[>0q") == "\(esc)P>|sunset(0.0.1)\(esc)\\")
    }

    @Test func `replies come in the order of the questions`() {
        #expect(answer("\(esc)[c\(esc)[5n\(esc)[6n") == "\(esc)[?62;22c\(esc)[0n\(esc)[1;1R")
    }

    @Test func `a query cut at every byte is answered the same`() {
        var terminal = Terminal(columns: 10, rows: 4)
        for byte in Array("\(esc)[3;5H\(esc)[6n\(esc)[?7$p".utf8) {
            [byte].withUnsafeBufferPointer { terminal.feed($0.span) }
        }
        #expect(String(decoding: terminal.takeReplies(), as: UTF8.self) == "\(esc)[3;5R\(esc)[?7;1$y")
    }

    @Test func `taking the replies empties the queue`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("\(esc)[5n")
        #expect(terminal.takeReplies() == Array("\(esc)[0n".utf8))
        #expect(terminal.takeReplies() == [])
    }

    @Test func `a flood of queries cannot grow the queue without bound`() {
        var terminal = Terminal(columns: 10, rows: 4)
        let query = String(repeating: "\(esc)[c", count: 100_000)
        terminal.feed(query)
        let replies = terminal.takeReplies()
        #expect(replies.count <= 65536)
        #expect(replies.count > 0)
        #expect(terminal.screen.droppedReplies > 0)
    }
}

@Suite("Modes and cursor style") struct ScreenModeTests {
    @Test func `cursor style`() {
        func style(_ n: Int) -> (CursorShape, Bool) {
            let s = screen("\(esc)[\(n) q")
            return (s.cursorShape, s.cursorBlinks)
        }
        #expect(style(0) == (.block, true))
        #expect(style(1) == (.block, true))
        #expect(style(2) == (.block, false))
        #expect(style(3) == (.underline, true))
        #expect(style(4) == (.underline, false))
        #expect(style(5) == (.bar, true))
        #expect(style(6) == (.bar, false))
        #expect(style(7) == (.block, true), "an unknown style changes nothing")
    }

    @Test func `modes the host needs are recorded`() {
        #expect(screen("\(esc)[?1h").modes.applicationCursorKeys)
        #expect(screen("\(esc)[?2004h").modes.bracketedPaste)
        #expect(screen("\(esc)[?1004h").modes.focusEvents)
        #expect(screen("\(esc)[?2026h").modes.synchronizedOutput)
        #expect(screen("\(esc)[?5h").modes.reverseVideo)
        #expect(screen("\(esc)[?25l").modes.cursorVisible == false)
        #expect(screen("\(esc)=").modes.applicationKeypad)
        #expect(screen("\(esc)=\(esc)>").modes.applicationKeypad == false)
    }

    @Test func `mouse tracking and format`() {
        #expect(screen("\(esc)[?1000h").modes.mouseTracking == .normal)
        #expect(screen("\(esc)[?1002h").modes.mouseTracking == .button)
        #expect(screen("\(esc)[?1003h").modes.mouseTracking == .any)
        #expect(screen("\(esc)[?9h").modes.mouseTracking == .x10)
        #expect(screen("\(esc)[?1000h\(esc)[?1000l").modes.mouseTracking == MouseTracking.none)
        #expect(
            screen("\(esc)[?1003h\(esc)[?1000l").modes.mouseTracking == .any,
            "resetting another level leaves the current one"
        )
        #expect(screen("\(esc)[?1006h").modes.mouseFormat == .sgr)
        #expect(screen("\(esc)[?1006h\(esc)[?1006l").modes.mouseFormat == .x10)
        #expect(screen("\(esc)[?1016h").modes.mouseFormat == .sgrPixels)
    }

    @Test func `soft reset restores modes, pen, region and saved cursor but keeps the text`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("ab\(esc)[?6h\(esc)[4h\(esc)[1m\(esc)[2;3r\(esc)[?25l\(esc)[?1h\(esc)[!p")
        #expect(terminal.screen.modes == Modes())
        #expect(terminal.screen.text(row: 0) == "ab")
        terminal.feed("\(esc)[1;3HXY")
        #expect(terminal.screen.text(row: 0) == "abXY", "insert mode is off")
        #expect(!terminal.screen.style(row: 0, column: 2).attributes.contains(.bold), "the pen is reset")
    }

    @Test func `soft reset resets the scroll region`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("\(esc)[2;3r\(esc)[!p\(esc)[H a\r\nb\r\nc\r\nd\r\ne")
        #expect((0 ..< 4).map { terminal.screen.text(row: $0) } == ["b", "c", "d", "e"])
    }
}

@Suite("Kitty keyboard flags") struct KeyboardFlagTests {
    @Test func `query, push, pop`() {
        #expect(answer("\(esc)[?u") == "\(esc)[?0u")
        #expect(answer("\(esc)[>1u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[?u") == "\(esc)[?2u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[<u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[>4u\(esc)[<2u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[<5u\(esc)[?u") == "\(esc)[?0u", "popping an empty stack leaves the defaults")
    }

    @Test func `set with modes 1 (replace), 2 (add) and 3 (remove)`() {
        #expect(answer("\(esc)[=5u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=5;1u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=1u\(esc)[=4;2u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=7u\(esc)[=2;3u\(esc)[?u") == "\(esc)[?5u")
    }

    @Test func `the main and alternate screens have separate stacks`() {
        #expect(answer("\(esc)[>1u\(esc)[?1049h\(esc)[?u") == "\(esc)[?0u")
        #expect(answer("\(esc)[>1u\(esc)[?1049h\(esc)[>4u\(esc)[?1049l\(esc)[?u") == "\(esc)[?1u")
        #expect(screen("\(esc)[>1u").keyboardFlags == 1)
    }

    @Test func `the stack is bounded`() {
        // Twenty pushes keep the newest sixteen: sixteen pops empty it, an unbounded stack would still hold four.
        let pushes = String(repeating: "\(esc)[>1u", count: 20)
        #expect(answer(pushes + "\(esc)[<16u\(esc)[?u") == "\(esc)[?0u")
        #expect(answer(String(repeating: "\(esc)[>1u", count: 100_000) + "\(esc)[<16u\(esc)[?u") == "\(esc)[?0u")
    }
}
