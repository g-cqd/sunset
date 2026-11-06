import AemiTestKit
import Testing

@testable import SunsetCore

@Suite("Scrollback") struct ScreenScrollbackTests {
    @Test func `lines that scroll off the top are kept, oldest first`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        #expect(rows(t) == ["3", "4", "5", "6"])
        #expect(history(t) == ["1", "2"])
    }

    @Test func `only full-screen scrolling of the primary screen saves lines`() {
        #expect(
            history(terminal("a\r\nb\r\nc\r\nd\(esc)[2;4r\(esc)[4;1H\n\n")).isEmpty,
            "a region below the top saves nothing"
        )
        #expect(history(terminal("a\r\nb\r\nc\r\nd\(esc)[1;1H\(esc)[M")).isEmpty, "deleting lines saves nothing")
        #expect(
            history(terminal("a\(esc)[?1049h1\r\n2\r\n3\r\n4\r\n5\r\n6")).isEmpty,
            "the alternate screen has no history"
        )
        #expect(
            history(terminal("a\r\nb\r\nc\r\nd\(esc)[1;3r\(esc)[3;1H\n")) == ["a"],
            "a region from the top saves what leaves it"
        )
    }

    @Test func `the ring keeps the newest lines`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6\r\n7\r\n8", 10, 2, limit: 3)
        #expect(history(t) == ["4", "5", "6"])
        #expect(rows(t) == ["7", "8"])
    }

    @Test func `a limit of zero keeps nothing`() {
        #expect(history(terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6", limit: 0)).isEmpty)
    }

    @Test func `ED 3 clears the history, ED 2 does not`() {
        var t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        t.feed("\(esc)[2J")
        #expect(history(t) == ["1", "2"])
        t.feed("\(esc)[3J")
        #expect(history(t).isEmpty)
        #expect(rows(t) == ["", "", "", ""])
    }

    @Test func `the wrap flag and styles travel with a line into the history`() {
        let t = terminal("\(esc)[31mabcdefghijk\r\n\r\n\r\n\r\n\r\n", 10, 3)
        #expect(t.screen.scrollbackCount >= 2)
        #expect(t.screen.isScrollbackWrapped(line: 0))
        #expect(!t.screen.isScrollbackWrapped(line: 1))
        #expect(t.screen.style(of: t.screen.scrollbackCell(line: 0, column: 3)).foreground == .indexed(1))
    }

    @Test func `styles in the history survive a style table rebuild when few are live`() {
        var t = Terminal(columns: 80, rows: 3)
        t.feed("\(esc)[38;2;9;8;7mkeep\r\n\r\n\r\n\r\n")
        // Seventy thousand distinct styles, each overwriting the one before on a single cell: the table fills, few are live.
        for index in 0 ..< 70_000 { t.feed("\r\(esc)[38;2;\(index & 255);\((index >> 8) & 255);1mx") }
        #expect(t.screen.style(of: t.screen.scrollbackCell(line: 0, column: 0)).foreground == .rgb(9, 8, 7))
    }

    @Test
    func
        `when the history alone needs more styles than fit, the oldest lines lose theirs and the screen keeps its own`()
    {
        var t = Terminal(columns: 80, rows: 3)
        t.feed("\(esc)[38;2;9;8;7mold\r\n\r\n\r\n\r\n")
        for index in 0 ..< 70_000 { t.feed("\(esc)[38;2;\(index & 255);\((index >> 8) & 255);1mx") }
        #expect(t.screen.style(of: t.screen.scrollbackCell(line: 0, column: 0)).foreground == .default)
        let last = 69_999
        // 70 000 is a multiple of 80: the last character is in the last column, the wrap pending.
        let column = 79
        #expect(
            t.screen.style(row: t.screen.cursorRow, column: column).foreground
                == .rgb(UInt8(last & 255), UInt8((last >> 8) & 255), 1)
        )
    }
}
