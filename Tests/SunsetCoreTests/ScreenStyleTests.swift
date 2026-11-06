import Testing

@testable import SunsetCore

@Suite("Screen: styles and the alternate screen") struct ScreenStyleTests {
    @Test func `SGR sets the style of the cells written`() {
        let h = make("\(esc)[1;31ma\(esc)[0mb")
        let a = h.screen.style(row: 0, column: 0)
        let b = h.screen.style(row: 0, column: 1)
        #expect(a.attributes.contains(.bold))
        #expect(a.foreground == .indexed(1))
        #expect(b == CellStyle())
    }

    @Test func `256-colour and truecolour, semicolon and colon forms`() {
        func fg(_ sgr: String) -> Color { make("\(esc)[\(sgr)mx").screen.style(row: 0, column: 0).foreground }
        #expect(fg("38;5;200") == .indexed(200))
        #expect(fg("38:5:200") == .indexed(200))
        #expect(fg("38;2;1;2;3") == .rgb(1, 2, 3))
        #expect(fg("38:2::1:2:3") == .rgb(1, 2, 3))
        #expect(fg("38:2:1:2:3") == .rgb(1, 2, 3))
        #expect(fg("91") == .indexed(9))
        #expect(fg("31;39") == .default)
    }

    @Test func `background colours, inverse and underline styles`() {
        let h = make("\(esc)[44;7;4:3ma")
        let style = h.screen.style(row: 0, column: 0)
        #expect(style.background == .indexed(4))
        #expect(style.attributes.contains(.inverse))
        #expect(style.underline == .curly)
        #expect(make("\(esc)[4;24ma").screen.style(row: 0, column: 0).underline == .none)
    }

    @Test func `erased cells take the current background`() {
        let h = make("\(esc)[42m\(esc)[2K")
        #expect(h.screen.style(row: 0, column: 5).background == .indexed(2))
        #expect(h.screen.style(row: 0, column: 5).attributes.isEmpty)
    }

    @Test func `many distinct styles do not exhaust the style table`() {
        var h = Harness(80, 24)
        for index in 0 ..< 200_000 {
            h.feed("\(esc)[38;2;\(index & 255);\((index >> 8) & 255);\(index >> 16)mx")
        }
        #expect(
            h.screen.style(row: 23, column: 79).foreground
                == .rgb(UInt8(199_999 & 255), UInt8((199_999 >> 8) & 255), 3)
        )
    }

    @Test func `the alternate screen is separate and 1049 saves and restores the cursor`() {
        var h = make("main\(esc)[?1049h")
        #expect(h.lines == ["", "", "", ""])
        h.feed("alt")
        #expect(h.lines == ["    alt", "", "", ""])
        h.feed("\(esc)[?1049l")
        #expect(h.lines == ["main", "", "", ""])
        #expect(h.cursor == [0, 4])
    }

    @Test func `47 switches without saving or clearing`() {
        var h = make("main\(esc)[?47h")
        #expect(h.lines == ["", "", "", ""])
        h.feed("alt\(esc)[?47l")
        #expect(h.lines == ["main", "", "", ""])
        h.feed("\(esc)[?47h")
        // The cursor was not moved by the switch, so the text sits where it was written, after "main".
        #expect(h.lines == ["    alt", "", "", ""])
    }
}
