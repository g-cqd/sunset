import Testing

@testable import SunsetCore

/// A terminal fed text, read back as rows of text (blank cells as spaces, trailing spaces trimmed) and the cursor position.
struct Harness {
    var terminal: Terminal
    init(_ columns: Int = 10, _ rows: Int = 4) { terminal = Terminal(columns: columns, rows: rows) }

    mutating func feed(_ text: String) { terminal.feed(text) }
    var screen: Screen { terminal.screen }
    var lines: [String] { (0 ..< screen.rows).map { screen.text(row: $0) } }
    var cursor: [Int] { [screen.cursorRow, screen.cursorColumn] }
}

func make(_ text: String, _ columns: Int = 10, _ rows: Int = 4) -> Harness {
    var harness = Harness(columns, rows)
    harness.feed(text)
    return harness
}

private let esc = "\u{1B}"

@Suite("Screen: printing and C0") struct ScreenPrintTests {
    @Test func `text is written from the top left and moves the cursor`() {
        let h = make("abc")
        #expect(h.lines == ["abc", "", "", ""])
        #expect(h.cursor == [0, 3])
    }

    @Test func `CR LF BS and TAB`() {
        let h = make("ab\r\ncd\u{08}X\tY")
        #expect(h.lines == ["ab", "cX      Y", "", ""])
        #expect(h.cursor == [1, 9])
    }

    @Test func `LF alone keeps the column`() {
        #expect(make("ab\ncd").lines == ["ab", "  cd", "", ""])
    }

    @Test func `text wraps at the right edge, the wrap waiting until the next character`() {
        var h = make("0123456789")
        #expect(h.cursor == [0, 9], "the cursor stays on the last column with the wrap pending")
        h.feed("A")
        #expect(h.lines == ["0123456789", "A", "", ""])
        #expect(h.cursor == [1, 1])
    }

    @Test func `a CR clears a pending wrap`() {
        #expect(make("0123456789\rZ").lines == ["Z123456789", "", "", ""])
    }

    @Test func `with autowrap off the last column is overwritten`() {
        #expect(make("\(esc)[?7l0123456789XY").lines == ["012345678Y", "", "", ""])
    }

    @Test func `the screen scrolls when text runs past the bottom`() {
        let h = make("a\r\nb\r\nc\r\nd\r\ne")
        #expect(h.lines == ["b", "c", "d", "e"])
        #expect(h.cursor == [3, 1])
    }

    @Test func `wide characters take two columns and wrap whole`() {
        var h = make("a日本")
        #expect(h.lines == ["a日本", "", "", ""])
        #expect(h.cursor == [0, 5])
        h = make("12345678日")
        #expect(h.lines == ["12345678日", "", "", ""])
        h = make("123456789日")
        #expect(h.lines == ["123456789", "日", "", ""], "a wide character that does not fit goes to the next line")
    }

    @Test func `overwriting half of a wide character blanks the other half`() {
        #expect(make("日\u{08}\u{08}x").lines == ["x", "", "", ""])
        #expect(make("日\u{08}x").lines == [" x", "", "", ""])
    }

    @Test func `insert mode pushes the text right`() {
        #expect(make("abcd\r\(esc)[4hXY").lines == ["XYabcd", "", "", ""])
    }

    @Test func `repeat and erase characters`() {
        #expect(make("a\(esc)[3b").lines == ["aaaa", "", "", ""])
        #expect(make("abcdef\r\(esc)[2X").lines == ["  cdef", "", "", ""])
    }
}

@Suite("Screen: cursor movement") struct ScreenCursorTests {
    @Test func `CUP CUU CUD CUF CUB move and clamp`() {
        #expect(make("\(esc)[3;5H").cursor == [2, 4])
        #expect(make("\(esc)[H").cursor == [0, 0])
        #expect(make("\(esc)[99;99H").cursor == [3, 9])
        #expect(make("\(esc)[3;3H\(esc)[A").cursor == [1, 2])
        #expect(make("\(esc)[3;3H\(esc)[2B").cursor == [4 - 1, 2])
        #expect(make("\(esc)[3;3H\(esc)[C").cursor == [2, 3])
        #expect(make("\(esc)[3;3H\(esc)[2D").cursor == [2, 0])
        #expect(make("\(esc)[3;3H\(esc)[99A").cursor == [0, 2])
    }

    @Test func `CHA VPA CNL CPL HPA`() {
        #expect(make("\(esc)[3;3H\(esc)[7G").cursor == [2, 6])
        #expect(make("\(esc)[3;3H\(esc)[1d").cursor == [0, 2])
        #expect(make("\(esc)[2;3H\(esc)[E").cursor == [2, 0])
        #expect(make("\(esc)[3;3H\(esc)[F").cursor == [1, 0])
        #expect(make("\(esc)[3;3H\(esc)[5`").cursor == [2, 4])
    }

    @Test func `moving the cursor clears a pending wrap`() {
        #expect(make("0123456789\(esc)[DX").lines == ["01234567X9", "", "", ""])
    }

    @Test func `save and restore the cursor`() {
        let h = make("\(esc)[2;3H\(esc)7\(esc)[H\(esc)8X")
        #expect(h.lines == ["", "  X", "", ""])
        #expect(make("\(esc)[2;3H\(esc)[s\(esc)[H\(esc)[uX").lines == ["", "  X", "", ""])
    }

    @Test func `tabs: default stops, set, clear, forward and back`() {
        #expect(make("\t").cursor == [0, 8])
        #expect(make("\t\t").cursor == [0, 9])
        #expect(make("\(esc)[3G\(esc)H\r\t").cursor == [0, 2])
        #expect(make("\(esc)[3G\(esc)H\(esc)[g\r\t").cursor == [0, 8])
        #expect(make("\(esc)[3g\t").cursor == [0, 9])
        #expect(make("\(esc)[2I").cursor == [0, 9])
        #expect(make("\(esc)[10G\(esc)[Z").cursor == [0, 8])
    }

    @Test
    func
        `a back-tab, backspace or cursor-left that moves the cursor clears the pending wrap, so the next character lands where the cursor is`()
    {
        // Ten columns, text in the last one (wrap pending), then the cursor moves back: what is typed next goes at the new cursor, not on the next line (ghostty wraps it, which no one wants).
        #expect(make("0123456789\(esc)[ZX").lines == ["01234567X9", "", "", ""])
        #expect(make("0123456789\u{08}X").lines == ["01234567X9", "", "", ""])
        #expect(make("0123456789\(esc)[2DX").lines == ["0123456X89", "", "", ""])
    }

    @Test func `IND NEL RI`() {
        #expect(make("ab\(esc)Dc").lines == ["ab", "  c", "", ""])
        #expect(make("ab\(esc)Ec").lines == ["ab", "c", "", ""])
        #expect(make("ab\(esc)[2;1H\(esc)Mc").lines == ["cb", "", "", ""])
    }
}

@Suite("Screen: erase, insert, delete, scroll") struct ScreenEditTests {
    @Test func `EL erases to the end, the start or the line`() {
        #expect(make("abcdef\(esc)[3G\(esc)[K").lines[0] == "ab")
        #expect(make("abcdef\(esc)[3G\(esc)[1K").lines[0] == "   def")
        #expect(make("abcdef\(esc)[3G\(esc)[2K").lines[0] == "")
    }

    @Test func `ED erases below, above or everything`() {
        let fill = "aaaa\r\nbbbb\r\ncccc\r\ndddd"
        #expect(make(fill + "\(esc)[2;3H\(esc)[J").lines == ["aaaa", "bb", "", ""])
        #expect(make(fill + "\(esc)[2;3H\(esc)[1J").lines == ["", "   b", "cccc", "dddd"])
        #expect(make(fill + "\(esc)[2J").lines == ["", "", "", ""])
    }

    @Test func `ICH DCH insert and delete characters`() {
        #expect(make("abcdef\(esc)[3G\(esc)[2@").lines[0] == "ab  cdef")
        #expect(make("abcdef\(esc)[3G\(esc)[2P").lines[0] == "abef")
    }

    @Test func `IL DL insert and delete lines inside the region`() {
        let fill = "aaaa\r\nbbbb\r\ncccc\r\ndddd"
        #expect(make(fill + "\(esc)[2;1H\(esc)[L").lines == ["aaaa", "", "bbbb", "cccc"])
        #expect(make(fill + "\(esc)[2;1H\(esc)[M").lines == ["aaaa", "cccc", "dddd", ""])
    }

    @Test func `SU and SD scroll the region`() {
        let fill = "aaaa\r\nbbbb\r\ncccc\r\ndddd"
        #expect(make(fill + "\(esc)[S").lines == ["bbbb", "cccc", "dddd", ""])
        #expect(make(fill + "\(esc)[T").lines == ["", "aaaa", "bbbb", "cccc"])
    }

    @Test func `a scroll region confines scrolling and homes the cursor`() {
        var h = make("aaaa\r\nbbbb\r\ncccc\r\ndddd\(esc)[2;3r")
        #expect(h.cursor == [0, 0])
        h.feed("\(esc)[3;1H\n")
        #expect(h.lines == ["aaaa", "cccc", "", "dddd"])
        h.feed("\(esc)[2;1H\(esc)M")
        #expect(h.lines == ["aaaa", "", "cccc", "dddd"])
    }

    @Test func `origin mode makes CUP relative to the region`() {
        let h = make("\(esc)[2;3r\(esc)[?6h\(esc)[1;1HX")
        #expect(h.lines == ["", "X", "", ""])
        #expect(h.cursor == [1, 1])
    }

    @Test func `DECALN fills the screen with E`() {
        #expect(make("\(esc)#8", 3, 2).lines == ["EEE", "EEE"])
    }

    @Test func `RIS resets the screen and the modes`() {
        let h = make("abc\(esc)[?7l\(esc)c")
        #expect(h.lines == ["", "", "", ""])
        #expect(h.cursor == [0, 0])
        #expect(make("\(esc)[?7l\(esc)c0123456789X").lines == ["0123456789", "X", "", ""])
    }
}

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

@Suite("Screen: wrap flags and dirty rows") struct ScreenTrackingTests {
    @Test func `a wrapped line is flagged and erasing its end unflags it`() {
        var h = make("0123456789A")
        #expect(h.screen.isWrapped(row: 0))
        #expect(!h.screen.isWrapped(row: 1))
        h.feed("\u{1B}[1;1H\u{1B}[K")
        #expect(!h.screen.isWrapped(row: 0))
        h = make("0123456789A\u{1B}[2J")
        #expect(!h.screen.isWrapped(row: 0))
    }

    @Test func `a row recycled by scrolling is not flagged`() {
        let h = make("0123456789A\r\n\n\n\n\n")
        #expect(h.screen.isWrapped(row: 0) == false)
        #expect(h.lines == ["", "", "", ""])
    }

    @Test func `1049 clears the alternate screen each time it is entered`() {
        var h = make("\u{1B}[?1049hjunk\u{1B}[?1049l\u{1B}[?1049h")
        #expect(h.lines == ["", "", "", ""])
        h.feed("\u{1B}[?1049l")
        #expect(h.lines == ["", "", "", ""])
    }

    @Test func `a new screen is wholly dirty, and clearing marks it clean`() {
        var h = Harness()
        #expect((0 ..< 4).allSatisfy { h.screen.isDirty(row: $0) })
        h.terminal.clearDirty()
        #expect((0 ..< 4).allSatisfy { !h.screen.isDirty(row: $0) })
    }

    @Test func `printing dirties its row only, and moving the cursor dirties none`() {
        var h = Harness()
        h.terminal.clearDirty()
        let before = h.screen.generation
        h.feed("\u{1B}[3;1H")
        #expect((0 ..< 4).allSatisfy { !h.screen.isDirty(row: $0) })
        #expect(h.screen.generation == before)
        h.feed("x")
        #expect((0 ..< 4).map { h.screen.isDirty(row: $0) } == [false, false, true, false])
        #expect(h.screen.generation != before)
    }

    @Test func `scrolling dirties the rows of the region`() {
        var h = make("\u{1B}[2;3r")
        h.terminal.clearDirty()
        h.feed("\u{1B}[3;1H\n")
        #expect((0 ..< 4).map { h.screen.isDirty(row: $0) } == [false, true, true, false])
    }

    @Test func `erasing and inserting dirty the rows they change`() {
        var h = make("abc\r\ndef")
        h.terminal.clearDirty()
        h.feed("\u{1B}[2;1H\u{1B}[K")
        #expect((0 ..< 4).map { h.screen.isDirty(row: $0) } == [false, true, false, false])
        h.terminal.clearDirty()
        h.feed("\u{1B}[1;1H\u{1B}[@")
        #expect((0 ..< 4).map { h.screen.isDirty(row: $0) } == [true, false, false, false])
    }

    @Test func `switching screens dirties everything`() {
        var h = make("x")
        h.terminal.clearDirty()
        h.feed("\u{1B}[?1049h")
        #expect((0 ..< 4).allSatisfy { h.screen.isDirty(row: $0) })
    }
}
