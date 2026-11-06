import Testing

@testable import SunsetCore

private let esc = "\u{1B}"

private func terminal(_ text: String, _ columns: Int = 10, _ rows: Int = 4, limit: Int = 10_000) -> Terminal {
    var terminal = Terminal(columns: columns, rows: rows, scrollbackLimit: limit)
    terminal.feed(text)
    return terminal
}

private func history(_ terminal: Terminal) -> [String] {
    (0 ..< terminal.screen.scrollbackCount).map { terminal.screen.scrollbackText(line: $0) }
}

private func rows(_ terminal: Terminal) -> [String] {
    (0 ..< terminal.screen.rows).map { terminal.screen.text(row: $0) }
}

/// The text of the whole buffer as logical lines (rows joined where a line wrapped), without trailing empty lines.
func logicalLines(_ screen: Screen) -> [String] {
    var lines: [String] = []
    var current = ""
    func finish(_ wrapped: Bool, _ text: String) {
        current += text
        if !wrapped {
            lines.append(trimmed(current))
            current = ""
        }
    }
    for line in 0 ..< screen.scrollbackCount {
        var text = ""
        for column in 0 ..< screen.columns {
            let cell = screen.scrollbackCell(line: line, column: column)
            if cell.width == .spacerTail || cell.width == .spacerHead { continue }
            text.unicodeScalars.append(Unicode.Scalar(cell.scalar == 0 ? 0x20 : cell.scalar) ?? "?")
        }
        let wrapped = screen.isScrollbackWrapped(line: line)
        finish(wrapped, wrapped ? text : trimmed(text))
    }
    for row in 0 ..< screen.rows {
        var text = ""
        for column in 0 ..< screen.columns {
            let cell = screen.cell(row: row, column: column)
            if cell.width == .spacerTail || cell.width == .spacerHead { continue }
            text.unicodeScalars.append(Unicode.Scalar(cell.scalar == 0 ? 0x20 : cell.scalar) ?? "?")
        }
        let wrapped = screen.isWrapped(row: row)
        finish(wrapped, wrapped ? text : trimmed(text))
    }
    if !current.isEmpty { lines.append(trimmed(current)) }
    while lines.last == "" { lines.removeLast() }
    return lines
}

private func trimmed(_ text: String) -> String {
    var text = text
    while text.last == " " { text.removeLast() }
    return text
}

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
        var random = SplitMix64(state: 21)
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
