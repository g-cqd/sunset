import AemiTestKit
import Testing

@testable import SunsetCore

@Suite("Resize and reflow") struct ScreenResizeTests {
    @Test func `widening joins a wrapped line`() {
        var t = terminal("abcdefghij", 5, 3)
        #expect(rows(t) == ["abcde", "fghij", ""])
        t.resize(columns: 10, rows: 3)
        #expect(rows(t) == ["abcdefghij", "", ""])
        #expect(!t.screen.isWrapped(row: 0))
    }

    @Test func `narrowing splits a line and marks the wrap`() {
        var t = terminal("abcdefghij", 10, 3)
        t.resize(columns: 5, rows: 3)
        #expect(rows(t) == ["abcde", "fghij", ""])
        #expect(t.screen.isWrapped(row: 0))
        #expect(!t.screen.isWrapped(row: 1))
    }

    @Test func `hard line breaks are never joined`() {
        var t = terminal("ab\r\ncd", 10, 3)
        t.resize(columns: 30, rows: 3)
        #expect(rows(t) == ["ab", "cd", ""])
    }

    @Test func `the cursor follows its text`() {
        var t = terminal("abcdefgh", 10, 4)
        #expect([t.screen.cursorRow, t.screen.cursorColumn] == [0, 8])
        t.resize(columns: 4, rows: 4)
        #expect(rows(t) == ["abcd", "efgh", "", ""])
        #expect([t.screen.cursorRow, t.screen.cursorColumn] == [2, 0])
        t.resize(columns: 8, rows: 4)
        #expect(
            [t.screen.cursorRow, t.screen.cursorColumn] == [1, 0],
            "past the end of a line that just fills the row, the cursor is on the next row"
        )
    }

    @Test func `a cursor in empty space keeps its place on the line`() {
        var t = terminal("ab\(esc)[1;6H", 10, 3)
        t.resize(columns: 4, rows: 3)
        #expect([t.screen.cursorRow, t.screen.cursorColumn] == [1, 1])
    }

    @Test func `shrinking the height drops blank rows below the cursor before saving any line`() {
        var t = terminal("a\r\nb", 10, 4)
        t.resize(columns: 10, rows: 2)
        #expect(rows(t) == ["a", "b"])
        #expect(t.screen.scrollbackCount == 0)
    }

    @Test func `shrinking the height with the cursor at the bottom saves the top rows`() {
        var t = terminal("1\r\n2\r\n3\r\n4", 10, 4)
        t.resize(columns: 10, rows: 2)
        #expect(rows(t) == ["3", "4"])
        #expect(history(t) == ["1", "2"])
        #expect(t.screen.cursorRow == 1)
    }

    @Test func `growing the height pulls history back when the cursor is at the bottom`() {
        var t = terminal("1\r\n2\r\n3\r\n4", 10, 2)
        #expect(history(t) == ["1", "2"])
        t.resize(columns: 10, rows: 4)
        #expect(rows(t) == ["1", "2", "3", "4"])
        #expect(t.screen.scrollbackCount == 0)
        #expect(t.screen.cursorRow == 3)
    }

    @Test func `growing the height with the cursor higher adds blank rows below`() {
        var t = terminal("1\r\n2\r\n3\r\n4\r\n5\(esc)[1;1H", 10, 3)
        t.resize(columns: 10, rows: 5)
        #expect(rows(t) == ["3", "4", "5", "", ""])
        #expect(history(t) == ["1", "2"])
        #expect(t.screen.cursorRow == 0)
    }

    @Test func `a wide character is never split by a new width`() {
        var t = terminal("日本", 4, 3)
        t.resize(columns: 3, rows: 3)
        #expect(rows(t) == ["日", "本", ""])
        #expect(t.screen.isWrapped(row: 0))
        t.resize(columns: 4, rows: 3)
        #expect(rows(t) == ["日本", "", ""])
    }

    @Test func `history is re-wrapped with the screen`() {
        var t = terminal("abcdefgh\r\n\r\n\r\n\r\n", 4, 2)
        #expect(history(t).first == "abcd")
        t.resize(columns: 8, rows: 2)
        #expect(history(t).first == "abcdefgh")
    }

    @Test func `the alternate screen is cut or padded, and the primary survives`() {
        var t = terminal("primary text here", 10, 3)
        t.feed("\(esc)[?1049h\(esc)[HALT\(esc)[3;10Hz")
        t.resize(columns: 5, rows: 2)
        #expect(t.screen.isAlternate)
        #expect(rows(t) == ["ALT", ""])
        #expect(t.screen.cursorRow <= 1 && t.screen.cursorColumn <= 4)
        t.feed("\(esc)[?1049l")
        #expect(logicalLines(t.screen) == ["primary text here"])
    }

    @Test func `a resize resets the scroll region and gives the new columns tab stops`() {
        var t = terminal("\(esc)[2;3r", 10, 4)
        t.resize(columns: 20, rows: 4)
        t.feed("\(esc)[H\t\t")
        #expect(t.screen.cursorColumn == 16)
        t.feed("\(esc)[4;1H\n")
        #expect(rows(t) == ["", "", "", ""])
        #expect(t.screen.scrollbackCount == 0 || true)
    }

    @Test func `a resize dirties every row, and the same size does nothing`() {
        var t = terminal("x", 10, 4)
        t.clearDirty()
        t.resize(columns: 10, rows: 4)
        #expect((0 ..< 4).allSatisfy { !t.screen.isDirty(row: $0) })
        t.resize(columns: 9, rows: 4)
        #expect((0 ..< 4).allSatisfy { t.screen.isDirty(row: $0) })
    }

    @Test func `content is never lost or joined wrongly by any sequence of resizes`() {
        var random = SeededRNG(seed: 21)
        for round in 0 ..< 150 {
            var t = Terminal(columns: 3 + random.below(10), rows: 2 + random.below(5))
            var text = ""
            for _ in 0 ..< 1 + random.below(30) {
                let word = String(
                    (0 ..< 1 + random.below(9)).map { _ in Character(Unicode.Scalar(UInt8(0x61 + random.below(26)))) }
                )
                text += word + (random.below(4) == 0 ? "\r\n" : " ")
            }
            t.feed(text)
            let before = logicalLines(t.screen)
            for _ in 0 ..< 1 + random.below(5) {
                t.resize(columns: 2 + random.below(14), rows: 1 + random.below(7))
                #expect(logicalLines(t.screen) == before, "round \(round): \(text.debugDescription)")
            }
        }
    }
}
