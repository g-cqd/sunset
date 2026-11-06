import Testing

@testable import SunsetCore

/// A history line is stored without its trailing blank cells (a blank in the default style is the zero word): most lines of terminal output are short,
/// and writing 120 cells for each into cold memory was 46 % of the time of a scrolling flood (measured: 52.5 ms against 28.5 ms without the copy).
@Suite("Scrollback: lines without their trailing blanks") struct ScrollbackTrimTests {
    private func row(_ text: String, columns: Int, style: UInt16 = 0) -> ArraySlice<Cell> {
        var cells = [Cell](repeating: .empty, count: columns)
        for (index, scalar) in text.unicodeScalars.enumerated() {
            cells[index] = Cell(scalar: scalar.value, width: .narrow, style: style)
        }
        return ArraySlice(cells)
    }

    @Test func `short lines take only the cells they use`() {
        var history = Scrollback(columns: 120, limit: 10_000)
        for _ in 0 ..< 1000 { history.push(row("abc", columns: 120), wrapped: false) }
        #expect(history.storedCells == 3000, "stored \(history.storedCells) cells for 1000 lines of 3")
    }

    @Test func `every column reads back as it was pushed, the trimmed ones as empty cells`() {
        var history = Scrollback(columns: 20, limit: 10_000)
        let lines = ["", "x", "hello world", "01234567890123456789", "a"]
        for (index, text) in lines.enumerated() { history.push(row(text, columns: 20), wrapped: index == 2) }
        for (index, text) in lines.enumerated() {
            let want = row(text, columns: 20)
            for column in 0 ..< 20 { #expect(history[index, column] == want[column], "line \(index) column \(column)") }
            #expect(history.isWrapped(index) == (index == 2))
        }
    }

    @Test func `a styled blank at the end of a line is content and is kept`() {
        var history = Scrollback(columns: 10, limit: 100)
        var cells = [Cell](repeating: .empty, count: 10)
        cells[6] = Cell(scalar: 0, width: .narrow, style: 5)
        history.push(ArraySlice(cells), wrapped: false)
        #expect(history[0, 6].styleID == 5)
        #expect(history.storedCells == 7)
    }

    @Test func `the styles of kept cells are remapped, and a line of blanks stays blank`() {
        var history = Scrollback(columns: 10, limit: 100)
        history.push(row("ab", columns: 10, style: 4), wrapped: false)
        history.push(row("", columns: 10), wrapped: false)
        history.mapStyles { $0 == 4 ? 9 : $0 }
        #expect(history[0, 0].styleID == 9 && history[0, 1].styleID == 9)
        #expect(history[0, 5] == .empty && history[1, 0] == .empty)
    }

    @Test func `eviction and sharing still work with variable-length lines`() {
        var history = Scrollback(columns: 30, limit: 300)
        for index in 0 ..< 2000 {
            history.push(row(String(repeating: "z", count: index % 30), columns: 30), wrapped: false)
        }
        let copy = history
        history.push(row("new", columns: 30), wrapped: false)
        #expect(history.count == 300 && copy.count == 300)
        #expect(history.sharesStorage(line: 10, with: copy))
        #expect(history.storedLines <= 300 + Scrollback.chunkLines)
        #expect(copy[299, 0].scalar == UInt32(("z" as Unicode.Scalar).value) || (1999 % 30) == 0)
    }
}
