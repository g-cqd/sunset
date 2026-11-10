/// Reading selected text, and finding the word and the line under a point.
extension Screen {
    /// Characters besides letters and digits that belong to a word when double-clicking (paths, addresses, options).
    public static let defaultWordCharacters = "_-./~:@%+=#?&"

    /// The lines of the history and the screen as one sequence: how many there are.
    public var absoluteLineCount: Int { scrollback.count + rows }

    /// The text of a selection. Lines are joined with line feeds, except where the screen wrapped a long line (that was one line); trailing spaces are
    /// dropped from each line; a wide character is taken whole whichever of its two cells was selected.
    public func text(of selection: Selection) -> String {
        let first = selection.start
        let last = min(selection.end, SelectionPoint(line: absoluteLineCount - 1, column: columns - 1))
        guard first.line >= 0, first.line <= last.line else { return "" }
        var result = String.UnicodeScalarView()
        for line in first.line ... last.line {
            var from = 0
            var through = columns - 1
            switch selection.shape {
                case .block:
                    from = max(0, min(selection.anchor.column, selection.head.column))
                    through = min(columns - 1, max(selection.anchor.column, selection.head.column))
                case .linear:
                    if line == first.line { from = max(0, first.column) }
                    if line == last.line { through = min(columns - 1, last.column) }
            }
            var scalars = String.UnicodeScalarView()
            if from <= through {
                if absoluteCell(line: line, column: from).width == .spacerTail, from > 0 { from -= 1 }
                for column in from ... through {
                    appendText(of: absoluteCell(line: line, column: column), to: &scalars)
                }
            }
            let wrapped = isAbsoluteWrapped(line: line) && selection.shape == .linear && line != last.line
            if !wrapped { while scalars.last == " " { scalars.removeLast() } }
            result.append(contentsOf: scalars)
            if line != last.line, !wrapped { result.append("\n") }
        }
        return String(result)
    }

    /// The first and last point of the word at `point` (a run of word characters, or of spaces, or one other character).
    public func wordRange(at point: SelectionPoint, wordCharacters: String = Screen.defaultWordCharacters) -> (
        start: SelectionPoint, end: SelectionPoint
    ) {
        let line = min(max(point.line, 0), absoluteLineCount - 1)
        var column = min(max(point.column, 0), columns - 1)
        if absoluteCell(line: line, column: column).width == .spacerTail, column > 0 { column -= 1 }
        let kind = wordKind(absoluteCell(line: line, column: column), wordCharacters)
        guard kind != .other else {
            return (
                SelectionPoint(line: line, column: column), SelectionPoint(line: line, column: wideEnd(line, column))
            )
        }
        var left = column
        while left > 0 {
            var previous = left - 1
            if absoluteCell(line: line, column: previous).width == .spacerTail, previous > 0 { previous -= 1 }
            guard wordKind(absoluteCell(line: line, column: previous), wordCharacters) == kind else { break }
            left = previous
        }
        var right = wideEnd(line, column)
        while right + 1 < columns {
            let next = absoluteCell(line: line, column: right + 1)
            guard wordKind(next, wordCharacters) == kind else { break }
            right = wideEnd(line, right + 1)
        }
        return (SelectionPoint(line: line, column: left), SelectionPoint(line: line, column: right))
    }

    /// The last column of the character that starts at `column` (the next one for a wide character).
    private func wideEnd(_ line: Int, _ column: Int) -> Int {
        absoluteCell(line: line, column: column).width == .wide && column + 1 < columns ? column + 1 : column
    }

    private enum WordKind { case word, space, other }

    private func wordKind(_ cell: Cell, _ wordCharacters: String) -> WordKind {
        if cell.scalar == 0 || cell.scalar == 0x20 { return .space }
        if cell.isCluster { return .word }
        guard let scalar = Unicode.Scalar(cell.scalar) else { return .other }
        if scalar.properties.isAlphabetic || scalar.properties.numericType != nil
            || wordCharacters.unicodeScalars.contains(scalar)
        {
            return .word
        }
        return .other
    }

    /// The first and last point of the whole line at `line`: every row it wraps across.
    public func lineRange(at line: Int) -> (start: SelectionPoint, end: SelectionPoint) {
        var first = min(max(line, 0), absoluteLineCount - 1)
        var last = first
        while first > 0, isAbsoluteWrapped(line: first - 1) { first -= 1 }
        while last + 1 < absoluteLineCount, isAbsoluteWrapped(line: last) { last += 1 }
        return (SelectionPoint(line: first, column: 0), SelectionPoint(line: last, column: columns - 1))
    }

    /// Whether `cell` carries real text (not empty or an ASCII space).
    private func isNonBlank(_ cell: Cell) -> Bool {
        cell.scalar != 0 && cell.scalar != 0x20
    }

    /// The first and last columns of `line` that contain non-blank text; nil when the line is wholly blank.
    func textColumns(on line: Int) -> (first: Int, last: Int)? {
        guard line >= 0, line < absoluteLineCount else { return nil }
        var first: Int?
        var last = 0
        for column in 0 ..< columns where isNonBlank(absoluteCell(line: line, column: column)) {
            if first == nil { first = column }
            last = wideEnd(line, column)
        }
        return first.map { ($0, last) }
    }

    /// Snaps `point` to the nearest real text for a double- or triple-click: trailing blanks snap to the end of the line's text, leading blanks to its start,
    /// and a wholly blank line to the nearest line with text.
    func nearestTextPoint(to point: SelectionPoint) -> SelectionPoint {
        let clampedLine = min(max(point.line, 0), absoluteLineCount - 1)
        let clampedColumn = min(max(point.column, 0), columns - 1)
        if let span = textColumns(on: clampedLine) {
            if clampedColumn > span.last { return SelectionPoint(line: clampedLine, column: span.last) }
            if clampedColumn < span.first { return SelectionPoint(line: clampedLine, column: span.first) }
            return SelectionPoint(line: clampedLine, column: clampedColumn)
        }
        for distance in 1 ..< absoluteLineCount {
            if clampedLine - distance >= 0, let span = textColumns(on: clampedLine - distance) {
                return SelectionPoint(line: clampedLine - distance, column: span.last)
            }
            if clampedLine + distance < absoluteLineCount, let span = textColumns(on: clampedLine + distance) {
                return SelectionPoint(line: clampedLine + distance, column: span.first)
            }
        }
        return SelectionPoint(line: clampedLine, column: clampedColumn)
    }

    /// Adjusts the starting anchor of a linear cell-by-cell drag when it started in trailing empty space past the end of a line's text (or on a blank line):
    /// dragging backwards snaps to the last real character before the anchor; dragging forwards across lines starts at the beginning of the next line.
    func snappedCellAnchor(_ anchor: SelectionPoint, toward head: SelectionPoint) -> SelectionPoint {
        let line = min(max(anchor.line, 0), absoluteLineCount - 1)
        let column = min(max(anchor.column, 0), columns - 1)
        let pastEnd: Bool
        if let span = textColumns(on: line) {
            pastEnd = column > span.last
        } else {
            pastEnd = true
        }
        guard pastEnd else { return anchor }
        if head < anchor {
            for search in stride(from: line, through: 0, by: -1) {
                if let span = textColumns(on: search) {
                    return SelectionPoint(line: search, column: span.last)
                }
            }
            return anchor
        }
        if head.line > line, line + 1 < absoluteLineCount {
            return SelectionPoint(line: line + 1, column: 0)
        }
        return anchor
    }
}
