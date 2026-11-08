import Testing

@testable import SunsetCore

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

    @Test func `a wide character that does not fit dirties the row it leaves blank at the end, and the next`() {
        var h = Harness()
        h.feed("\u{1B}[2;10H")
        h.terminal.clearDirty()
        h.feed("日")
        #expect((0 ..< 4).map { h.screen.isDirty(row: $0) } == [false, true, true, false])
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
