import Testing

@testable import SunsetCore

@Suite("Grapheme clusters") struct ScreenGraphemeTests {
    @Test func `a combining mark joins the cell before it`() {
        let h = make("e\u{301}x")
        #expect(h.lines[0] == "e\u{301}x")
        #expect(h.cursor == [0, 2])
        #expect(h.screen.cell(row: 0, column: 0).width == .narrow)
        #expect(h.screen.cell(row: 0, column: 1).scalar == 0x78)
    }

    @Test func `several marks join the same cell`() {
        let h = make("a\u{301}\u{323}b")
        #expect(h.lines[0] == "a\u{301}\u{323}b")
        #expect(h.cursor == [0, 2])
    }

    @Test func `a mark after the cursor was moved joins nothing`() {
        #expect(make("e\(esc)[C\u{301}").lines[0] == "e")
        #expect(make("e\r\u{301}").lines[0] == "e")
        #expect(make("\u{301}").lines[0] == "", "a mark with nothing before it is dropped")
    }

    @Test func `a mark arriving in a later piece still joins`() {
        var terminal = Terminal(columns: 10, rows: 4)
        for byte in Array("e\u{301}x".utf8) { [byte].withUnsafeBufferPointer { terminal.feed($0.span) } }
        #expect(terminal.screen.text(row: 0) == "e\u{301}x")
    }

    @Test func `a joiner sequence is one wide cluster`() {
        let h = make("👨\u{200D}👩\u{200D}👧x")
        #expect(h.lines[0] == "👨\u{200D}👩\u{200D}👧x")
        #expect(h.cursor == [0, 3])
        #expect(h.screen.cell(row: 0, column: 0).width == .wide)
    }

    @Test func `a skin tone modifier joins its emoji`() {
        let h = make("👍🏽x")
        #expect(h.lines[0] == "👍🏽x")
        #expect(h.cursor == [0, 3])
    }

    @Test func `a flag is two regional indicators in one cluster, a third starts the next`() {
        let h = make("🇯🇵🇫")
        #expect(h.cursor == [0, 4])
        #expect(h.lines[0] == "🇯🇵🇫")
        #expect(h.screen.cell(row: 0, column: 0).width == .wide)
        #expect(h.screen.cell(row: 0, column: 2).width == .wide)
    }

    @Test func `emoji presentation selector widens the cell`() {
        let h = make("❤\u{FE0F}x")
        #expect(h.lines[0] == "❤\u{FE0F}x")
        #expect(h.cursor == [0, 3])
        #expect(h.screen.cell(row: 0, column: 0).width == .wide)
    }

    @Test func `a mark joins the last cell of a full row`() {
        let h = make("123456789e\u{301}")
        #expect(h.lines[0] == "123456789e\u{301}")
        #expect(h.cursor == [0, 9])
    }

    @Test func `a cluster is overwritten and erased like any cell`() {
        #expect(make("e\u{301}\r\u{08}x").lines[0] == "x")
        #expect(make("e\u{301}\(esc)[1G\(esc)[X").lines[0] == "")
    }

    @Test func `clusters survive scrolling into history and a resize`() {
        var terminal = Terminal(columns: 10, rows: 2)
        terminal.feed("e\u{301}\r\n\r\n\r\n")
        #expect(terminal.screen.scrollbackText(line: 0) == "e\u{301}")
        terminal.resize(columns: 3, rows: 2)
        #expect(terminal.screen.scrollbackText(line: 0) == "e\u{301}")
    }

    @Test func `the table of clusters is bounded: past the limit marks are dropped, bases are kept`() {
        var terminal = Terminal(columns: 80, rows: 4, clusterLimit: 3)
        terminal.feed("a\u{301}b\u{302}c\u{303}d\u{304}e\u{305}")
        #expect(terminal.screen.text(row: 0) == "a\u{301}b\u{302}c\u{303}de")
    }

    @Test func `repeated clusters share one table entry`() {
        var terminal = Terminal(columns: 80, rows: 4, clusterLimit: 2)
        terminal.feed(String(repeating: "e\u{301}", count: 50))
        #expect(terminal.screen.text(row: 0) == String(repeating: "e\u{301}", count: 50))
    }
}
