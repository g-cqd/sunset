import Testing

@testable import SunsetCore

/// Tests VT400/xterm conformance additions from T-4 / t219 (esctest & vttest gaps):
/// - Rectangular area operations: `DECFRA` (`$x`), `DECERA` (`$z`), `DECCRA` (`$v`) with overlap and origin mode
/// - Reverse wraparound (`DECSET 45`) and pending-wrap backspace semantics
/// - Private mode save/restore (`XTSAVE` `CSI ? Pm s` / `XTRESTORE` `CSI ? Pm r`)
@Suite("VT400 / esctest conformance") struct VTConformanceTests {
    @Test func `DECFRA fills, DECCRA copies with overlap, and DECERA erases rectangular areas`() {
        var t = Terminal(columns: 8, rows: 4)
        // Fill 2..3 rows, 2..5 cols with '#' (0x23 = 35)
        t.feed("\(esc)[35;2;2;3;5$x")
        #expect(t.screen.text(row: 0) == "")
        #expect(t.screen.text(row: 1) == " ####")
        #expect(t.screen.text(row: 2) == " ####")

        // Copy rows 2..3 cols 2..4 to overlapping destination row 1 col 3 (`DECCRA`)
        t.feed("\(esc)[2;2;3;4;1;1;3;1$v")
        #expect(t.screen.text(row: 0) == "  ###")
        #expect(t.screen.text(row: 1) == " ####")

        // Erase center rectangle rows 1..2 cols 3..4 (`DECERA`)
        t.feed("\(esc)[1;3;2;4$z")
        #expect(t.screen.text(row: 0) == "    #")
        #expect(t.screen.text(row: 1) == " #  #")
    }

    @Test func `DECSET 45 reverse wraparound and pending-wrap BS behavior`() {
        var t = Terminal(columns: 4, rows: 3)
        // Enable reverse wraparound (`CSI ? 45 h`), verify DECRQM reports set (1).
        t.feed("\(esc)[?45h\(esc)[?45$p")
        #expect(String(decoding: t.takeReplies(), as: UTF8.self) == "\(esc)[?45;1$y")

        // Write 4 chars -> pendingWrap at col 3; first BS clears pendingWrap staying at col 3 (xterm/DEC standard).
        t.feed("abcd\u{08}X")
        #expect(t.screen.text(row: 0) == "abcX")

        // Wrap onto line 1 ("abcX" + "e" -> row 1 col 1), then BS twice wraps back to row 0 col 3!
        t.feed("e\u{08}\u{08}Z")
        #expect(t.screen.text(row: 0) == "abcZ")
    }

    @Test func `XTSAVE and XTRESTORE save and restore DEC private modes`() {
        var t = Terminal(columns: 10, rows: 4)
        #expect(t.screen.modes.autoWrap)
        #expect(!t.screen.modes.bracketedPaste)

        // Save modes 7 (autoWrap=true) and 2004 (bracketedPaste=false), then flip both.
        t.feed("\(esc)[?7;2004s\(esc)[?7l\(esc)[?2004h")
        #expect(!t.screen.modes.autoWrap)
        #expect(t.screen.modes.bracketedPaste)

        // Restore both via XTRESTORE (`CSI ? 7 ; 2004 r`).
        t.feed("\(esc)[?7;2004r")
        #expect(t.screen.modes.autoWrap)
        #expect(!t.screen.modes.bracketedPaste)
    }
}
