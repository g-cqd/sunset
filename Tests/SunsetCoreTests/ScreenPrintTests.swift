import Testing

@testable import SunsetCore

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
