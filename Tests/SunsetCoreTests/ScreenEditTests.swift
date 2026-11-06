import Testing

@testable import SunsetCore

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
