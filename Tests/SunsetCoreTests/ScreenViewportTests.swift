import Testing

@testable import SunsetCore

@Suite("Viewport") struct ScreenViewportTests {
    private func view(_ t: Terminal, back: Int) -> [String] {
        (0 ..< t.screen.rows).map { t.screen.viewportText(row: $0, scrolledBack: back) }
    }

    @Test func `scrolled back by nothing the viewport is the screen`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        #expect(view(t, back: 0) == ["3", "4", "5", "6"])
    }

    @Test func `scrolled back by n the viewport shows n more lines of history at the top`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        #expect(view(t, back: 1) == ["2", "3", "4", "5"])
        #expect(view(t, back: 2) == ["1", "2", "3", "4"])
    }

    @Test func `scrolling back past the oldest line stops at the oldest line`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        #expect(view(t, back: 99) == ["1", "2", "3", "4"])
        #expect(view(t, back: -3) == ["3", "4", "5", "6"])
    }

    @Test func `a viewport cell is the cell of that line, with its style`() {
        let t = terminal("\(esc)[31mred\r\n\(esc)[0m2\r\n3\r\n4\r\n5")
        let cell = t.screen.viewportCell(row: 0, column: 0, scrolledBack: 1)
        #expect(t.screen.style(of: cell).foreground != .default, "the history line is red")
        #expect(t.screen.style(row: 0, column: 0).foreground == .default, "the screen's first line is not")
        #expect(cell.scalar == UInt32(UInt8(ascii: "r")))
    }

    @Test func `the viewport knows which of its lines are wrapped`() {
        let t = terminal("abcdefghij1234\r\nx\r\ny\r\nz")
        #expect(t.screen.isViewportWrapped(row: 0, scrolledBack: t.screen.scrollbackCount))
    }

    /// Every row of the window, every amount of scrolling: the row's cells, padded with empty cells, are the window's cells one by one.
    private func expectRowsMatchCells(_ screen: Screen) {
        for back in 0 ... screen.scrollbackCount {
            for row in 0 ..< screen.rows {
                let cells = screen.viewportRow(row, scrolledBack: back)
                #expect(cells.count <= screen.columns)
                for column in 0 ..< screen.columns {
                    let expected = screen.viewportCell(row: row, column: column, scrolledBack: back)
                    let read = column < cells.count ? cells[cells.startIndex + column] : Cell.empty
                    #expect(read == expected, "row \(row) column \(column) back \(back)")
                }
            }
        }
    }

    @Test func `a window row read at once is its cells read one by one, in the history and on the screen`() {
        let t = terminal("\(esc)[31mred\(esc)[0m\r\nlonger line\r\n\r\n3\r\nabcdefghijklm\r\n5\r\n6")
        expectRowsMatchCells(t.screen)
    }

    @Test func `a window row of packed history is its cells read one by one`() {
        var t = Terminal(columns: 16, rows: 3, scrollbackLimit: 10_000)
        for line in 0 ..< 1000 {
            t.feed(
                String(repeating: String(UnicodeScalar(UInt8(97 + line % 26))), count: line % 3 == 0 ? 16 : 5) + "\r\n"
            )
        }
        t.packHistory(using: WordRunCodec(), keepingRecent: 1, limit: .max)
        #expect(t.screen.historyFootprint.packedChunks > 0)
        expectRowsMatchCells(t.screen)
    }
}
