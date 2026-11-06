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
}
