import Testing

@testable import SunsetCore

/// What a renderer needs to move pixels instead of drawing again: for each row, where its cells were at the last `clearDirty`, when a scroll brought them
/// there unchanged.
@Suite("Screen: rows moved by scrolling") struct ScreenMovedRowsTests {
    private func moved(_ h: Harness) -> [Int?] { (0 ..< h.screen.rows).map { h.screen.movedFrom(row: $0) } }

    private func cleared(_ text: String = "a\r\nb\r\nc\r\nd") -> Harness {
        var h = Harness()
        h.feed(text)
        h.terminal.clearDirty()
        return h
    }

    @Test func `rows that did not change are where they were`() {
        let h = cleared()
        #expect(moved(h) == [0, 1, 2, 3])
    }

    @Test func `a line feed at the bottom moves every row up one, and the new row comes from nowhere`() {
        var h = cleared()
        h.feed("\n")
        #expect(moved(h) == [1, 2, 3, nil])
        #expect((0 ..< 4).allSatisfy { h.screen.isDirty(row: $0) }, "moved rows are still dirty: their content changed")
    }

    @Test func `scrolls between two clears add up`() {
        var h = cleared()
        h.feed("\n\n")
        #expect(moved(h) == [2, 3, nil, nil])
    }

    @Test func `a row written after it moved has moved from nowhere`() {
        var h = cleared()
        h.feed("\n\u{1B}[1;1Hx")
        #expect(moved(h) == [nil, 2, 3, nil])
    }

    @Test func `a row written before it moved carries that with it`() {
        var h = cleared()
        h.feed("\u{1B}[4;1Hx\n")
        #expect(moved(h) == [1, 2, nil, nil])
    }

    @Test func `scrolling down moves rows down`() {
        var h = cleared()
        h.feed("\u{1B}[T")
        #expect(moved(h) == [nil, 0, 1, 2])
    }

    @Test func `a scroll region moves its rows only`() {
        var h = cleared()
        h.feed("\u{1B}[2;3r\u{1B}[3;1H\n")
        #expect(moved(h) == [0, 2, nil, 3])
    }

    @Test func `inserting and deleting lines move the rows below the cursor`() {
        var h = cleared()
        h.feed("\u{1B}[2;1H\u{1B}[M")
        #expect(moved(h) == [0, 2, 3, nil])
        h = cleared()
        h.feed("\u{1B}[2;1H\u{1B}[L")
        #expect(moved(h) == [0, nil, 1, 2])
    }

    @Test func `clearing the marks makes every row its own origin again`() {
        var h = cleared()
        h.feed("\n")
        h.terminal.clearDirty()
        #expect(moved(h) == [0, 1, 2, 3])
    }

    @Test func `erasing, the alternate screen and a resize leave no row moved`() {
        var h = cleared()
        h.feed("\n\u{1B}[2J")
        #expect(moved(h) == [nil, nil, nil, nil])
        h = cleared()
        h.feed("\u{1B}[?1049h")
        #expect(moved(h) == [nil, nil, nil, nil])
        h = cleared()
        h.terminal.resize(columns: 8, rows: 4)
        #expect(moved(h) == [nil, nil, nil, nil])
    }
}
