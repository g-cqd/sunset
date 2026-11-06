/// Reading the screen through a window that can be scrolled back into the history: line `row` of the window, with the window `scrolledBack` lines above the
/// live screen (0 is the live screen; the most is the history's length, and a value outside that is brought inside it).
extension Screen {
    /// The history's lines come first, then the screen's: this is where line `row` of the window is in that one sequence.
    private func line(row: Int, scrolledBack: Int) -> Int {
        row + scrollback.count - min(max(scrolledBack, 0), scrollback.count)
    }

    /// The cell at `column` of `line`, the lines counted from the oldest of the history.
    func absoluteCell(line: Int, column: Int) -> Cell {
        line < scrollback.count ? scrollback[line, column] : grid[line - scrollback.count, column]
    }

    /// Whether `line` continues on the next one (it wrapped).
    func isAbsoluteWrapped(line: Int) -> Bool {
        line < scrollback.count ? scrollback.isWrapped(line) : isWrapped(row: line - scrollback.count)
    }

    public func viewportCell(row: Int, column: Int, scrolledBack: Int) -> Cell {
        absoluteCell(line: line(row: row, scrolledBack: scrolledBack), column: column)
    }

    public func viewportText(row: Int, scrolledBack: Int) -> String {
        var scalars = String.UnicodeScalarView()
        for column in 0 ..< columns {
            appendText(of: viewportCell(row: row, column: column, scrolledBack: scrolledBack), to: &scalars)
        }
        var text = String(scalars)
        while text.last == " " { text.removeLast() }
        return text
    }

    /// Whether the line continues on the next one (it wrapped).
    public func isViewportWrapped(row: Int, scrolledBack: Int) -> Bool {
        isAbsoluteWrapped(line: line(row: row, scrolledBack: scrolledBack))
    }
}
