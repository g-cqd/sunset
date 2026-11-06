import Testing

@testable import SunsetCore

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
