import Testing

@testable import SunsetCore

@Suite("Selection") struct ScreenSelectionTests {
    private func point(_ line: Int, _ column: Int) -> SelectionPoint { SelectionPoint(line: line, column: column) }

    private func text(
        _ t: Terminal,
        from: SelectionPoint,
        to: SelectionPoint,
        shape: Selection.Shape = .linear
    ) -> String {
        t.screen.text(of: Selection(anchor: from, head: to, shape: shape))
    }

    @Test func `a selection on one line is the text between its ends, both included`() {
        let t = terminal("hello world", 20)
        #expect(text(t, from: point(0, 6), to: point(0, 10)) == "world")
        #expect(text(t, from: point(0, 0), to: point(0, 0)) == "h")
    }

    @Test func `dragging backwards selects the same text`() {
        let t = terminal("hello world", 20)
        #expect(text(t, from: point(0, 10), to: point(0, 6)) == "world")
    }

    @Test func `lines are joined with line feeds and their trailing spaces dropped`() {
        let t = terminal("one\r\ntwo  \r\nthree")
        #expect(text(t, from: point(0, 1), to: point(2, 2)) == "ne\ntwo\nthr")
    }

    @Test func `a selection that runs past the end of the text does not add spaces`() {
        let t = terminal("abc")
        #expect(text(t, from: point(0, 0), to: point(0, 9)) == "abc")
    }

    @Test func `a line that wrapped is one line: no line feed where the screen broke it`() {
        let t = terminal("abcdefghij1234\r\nnext")
        #expect(text(t, from: point(0, 0), to: point(1, 3)) == "abcdefghij1234")
        #expect(text(t, from: point(0, 0), to: point(2, 3)) == "abcdefghij1234\nnext")
    }

    @Test func `a block is the same columns of each line`() {
        let t = terminal("abcdef\r\nghijkl\r\nmnopqr")
        #expect(text(t, from: point(0, 2), to: point(2, 4), shape: .block) == "cde\nijk\nopq")
        #expect(text(t, from: point(2, 4), to: point(0, 2), shape: .block) == "cde\nijk\nopq")
    }

    @Test func `history lines are selectable, counted from the oldest`() {
        let t = terminal("1\r\n2\r\n3\r\n4\r\n5\r\n6")
        #expect(t.screen.absoluteLineCount == 6)
        #expect(text(t, from: point(0, 0), to: point(5, 0)) == "1\n2\n3\n4\n5\n6")
        #expect(text(t, from: point(1, 0), to: point(2, 0)) == "2\n3")
    }

    @Test func `a wide character is selected whole from either of its cells`() {
        let t = terminal("a\u{4E2D}b")
        #expect(text(t, from: point(0, 2), to: point(0, 2)) == "\u{4E2D}")
        #expect(text(t, from: point(0, 1), to: point(0, 1)) == "\u{4E2D}")
        #expect(text(t, from: point(0, 0), to: point(0, 1)) == "a\u{4E2D}")
    }

    @Test func `a cluster is selected as the characters it is made of`() {
        let t = terminal("e\u{0301}x")
        #expect(text(t, from: point(0, 0), to: point(0, 0)) == "e\u{0301}")
    }

    @Test func `blank cells inside a line are spaces`() {
        let t = terminal("a\(esc)[4Cb")
        #expect(text(t, from: point(0, 0), to: point(0, 5)) == "a    b")
    }

    @Test func `a double click selects the word: letters, digits and the characters of paths`() {
        let t = terminal("see /usr/local/bin now", 30)
        let word = t.screen.wordRange(at: point(0, 8))
        #expect(word.start == point(0, 4) && word.end == point(0, 17))
    }

    @Test func `a double click on spaces selects the run of spaces, on punctuation that one character`() {
        let t = terminal("a   b(c)")
        let spaces = t.screen.wordRange(at: point(0, 2))
        #expect(spaces.start == point(0, 1) && spaces.end == point(0, 3))
        let paren = t.screen.wordRange(at: point(0, 5))
        #expect(paren.start == point(0, 5) && paren.end == point(0, 5))
    }

    @Test func `a word on the second half of a wide character starts at its first cell`() {
        let t = terminal("\u{4E2D}\u{6587} x")
        let word = t.screen.wordRange(at: point(0, 1))
        #expect(word.start == point(0, 0) && word.end == point(0, 3))
    }

    @Test func `a triple click selects the whole line, across the rows it wrapped over`() {
        let t = terminal("abcdefghij1234\r\nnext")
        let range = t.screen.lineRange(at: 1)
        #expect(range.start == point(0, 0) && range.end == point(1, 9))
        let second = t.screen.lineRange(at: 2)
        #expect(second.start == point(2, 0) && second.end == point(2, 9))
    }

    @Test func `a selection contains the cells between its ends, or the block they span`() {
        let linear = Selection(anchor: point(1, 5), head: point(3, 2))
        #expect(linear.contains(line: 2, column: 0) && linear.contains(line: 2, column: 9))
        #expect(linear.contains(line: 1, column: 5) && !linear.contains(line: 1, column: 4))
        #expect(linear.contains(line: 3, column: 2) && !linear.contains(line: 3, column: 3))
        #expect(!linear.contains(line: 0, column: 5) && !linear.contains(line: 4, column: 0))
        let block = Selection(anchor: point(1, 5), head: point(3, 2), shape: .block)
        #expect(
            block.contains(line: 2, column: 3) && block.contains(line: 1, column: 2)
                && block.contains(line: 3, column: 5)
        )
        #expect(!block.contains(line: 2, column: 6) && !block.contains(line: 2, column: 1))
    }
}
