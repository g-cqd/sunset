import AemiRegex

/// Plain-text and RE2 regular-expression search across a terminal's entire scrollback history and live screen
/// (T-3 / roadmap 0026; zero-allocation literal fast path added in t185).
///
/// Wrapped physical rows are joined into logical lines before matching so a query finds text split across a terminal
/// wrap boundary, and every byte offset in the logical line maps back cleanly to `(absoluteLine, column)` — covering
/// wide characters (2 columns) and grapheme clusters accurately.
extension Screen {
    /// Searches the entire scrollback + live screen for `query`, returning matches in top-to-bottom order.
    /// Uses a zero-allocation byte scanner for literal queries (case-sensitive or ASCII case-insensitive) and
    /// `AemiRegex.Pattern` (RE2 linear-time engine, ReDoS-safe) for regex or non-ASCII case-insensitive queries.
    public func search(_ query: SearchQuery, limit: Int = SearchResult.defaultLimit) -> SearchResult {
        guard !query.text.isEmpty, limit > 0 else { return .empty }
        if !query.isRegex {
            let needle = Array(query.text.utf8)
            if query.matchCase {
                return scanLines(limit: limit) { bytes, emit in
                    Self.forEachLiteral(needle, in: bytes, asciiFold: false, emit: emit)
                }
            }
            if needle.allSatisfy({ $0 < 0x80 }) {
                let lowered = needle.map { ($0 >= 0x41 && $0 <= 0x5A) ? ($0 | 0x20) : $0 }
                return scanLines(limit: limit) { bytes, emit in
                    Self.forEachLiteral(lowered, in: bytes, asciiFold: true, emit: emit)
                }
            }
        }
        let source = query.isRegex ? query.text : Self.escapeRegexLiteral(query.text)
        let effective = query.matchCase ? source : "(?i)" + source
        let pattern: Pattern
        do {
            pattern = try Pattern(effective)
        } catch {
            return SearchResult(matches: [], error: "\(error)")
        }
        return scanLines(limit: limit) { bytes, emit in
            pattern.forEachMatch(in: bytes) { match in emit(match.range) }
        }
    }

    private func scanLines(
        limit: Int,
        find: ([UInt8], (Range<Int>) -> Bool) -> Void
    ) -> SearchResult {
        let total = absoluteLineCount
        guard total > 0 else { return .empty }

        var matches: [SearchMatch] = []
        var truncated = false
        var line = 0
        var bytes: [UInt8] = []
        bytes.reserveCapacity(columns * 2)
        var positions: [(line: Int, startColumn: Int, endColumn: Int)] = []
        var scratch: [UInt8] = []
        scratch.reserveCapacity(16)
        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(4)

        while line < total {
            let endLine = assembleBytes(startingAt: line, total: total, bytes: &bytes, scalars: &scalars)
            if !bytes.isEmpty {
                var builtPositions = false
                find(bytes) { range in
                    guard !range.isEmpty else { return true }
                    if !builtPositions {
                        fillPositions(
                            for: line ... endLine,
                            byteCount: bytes.count,
                            positions: &positions,
                            scratch: &scratch,
                            scalars: &scalars
                        )
                        builtPositions = true
                    }
                    guard range.lowerBound < positions.count, range.upperBound <= positions.count else { return true }
                    let first = positions[range.lowerBound]
                    let last = positions[range.upperBound - 1]
                    matches.append(
                        SearchMatch(
                            start: SelectionPoint(line: first.line, column: first.startColumn),
                            end: SelectionPoint(line: last.line, column: last.endColumn)
                        )
                    )
                    if matches.count >= limit {
                        truncated = true
                        return false
                    }
                    return true
                }
                if truncated { break }
            }
            line = endLine + 1
        }
        return SearchResult(matches: matches, truncated: truncated)
    }

    private func assembleBytes(
        startingAt line: Int,
        total: Int,
        bytes: inout [UInt8],
        scalars: inout String.UnicodeScalarView
    ) -> Int {
        bytes.removeAll(keepingCapacity: true)
        var endLine = line
        while true {
            forEachAbsoluteCell(on: endLine) { cell, _, _ in
                appendCellUTF8(cell, to: &bytes, scalars: &scalars)
            }
            if !(isAbsoluteWrapped(line: endLine) && endLine + 1 < total) {
                while bytes.last == 0x20 { bytes.removeLast() }
                return endLine
            }
            endLine += 1
        }
    }

    private func fillPositions(
        for rows: ClosedRange<Int>,
        byteCount: Int,
        positions: inout [(line: Int, startColumn: Int, endColumn: Int)],
        scratch: inout [UInt8],
        scalars: inout String.UnicodeScalarView
    ) {
        positions.removeAll(keepingCapacity: true)
        for rowIndex in rows {
            forEachAbsoluteCell(on: rowIndex) { cell, startColumn, endColumn in
                scratch.removeAll(keepingCapacity: true)
                appendCellUTF8(cell, to: &scratch, scalars: &scalars) {
                    positions.append((line: rowIndex, startColumn: startColumn, endColumn: endColumn))
                }
            }
        }
        while positions.count > byteCount { positions.removeLast() }
    }

    private static func forEachLiteral(
        _ needle: [UInt8],
        in haystack: [UInt8],
        asciiFold: Bool,
        emit: (Range<Int>) -> Bool
    ) {
        guard haystack.count >= needle.count, let firstByte = needle.first else { return }
        var i = 0
        let lastStart = haystack.count - needle.count
        while i <= lastStart {
            let raw = haystack[i]
            let b = asciiFold && raw >= 0x41 && raw <= 0x5A ? (raw | 0x20) : raw
            if b == firstByte, matchesLiteral(needle, in: haystack, at: i, asciiFold: asciiFold) {
                guard emit(i ..< i + needle.count) else { return }
                i += needle.count
            } else {
                i += 1
            }
        }
    }

    private static func matchesLiteral(_ needle: [UInt8], in haystack: [UInt8], at start: Int, asciiFold: Bool) -> Bool
    {
        for offset in 1 ..< needle.count {
            let raw = haystack[start + offset]
            let folded = asciiFold && raw >= 0x41 && raw <= 0x5A ? (raw | 0x20) : raw
            if folded != needle[offset] { return false }
        }
        return true
    }

    /// Walks every non-spacer cell on `line` (absolute index: scrollback then primary grid), invoking `body` with the
    /// cell and its inclusive `[startColumn, endColumn]` range. Shared by `Screen+Search` and `Screen+Snapshot`.
    func forEachAbsoluteCell(on line: Int, _ body: (Cell, Int, Int) -> Void) {
        let rowCells: ArraySlice<Cell>
        if line < scrollback.count {
            rowCells = scrollback.cells(line: line)
        } else {
            let base = grid.base(line - scrollback.count)
            rowCells = grid.cells[base ..< base + columns]
        }
        let limit = min(rowCells.count, columns)
        var column = 0
        while column < limit {
            let cell = rowCells[rowCells.startIndex + column]
            if cell.width == .spacerTail {
                column += 1
                continue
            }
            let endColumn = cell.width == .wide && column + 1 < columns ? column + 1 : column
            body(cell, column, endColumn)
            column = endColumn + 1
        }
    }

    /// Appends UTF-8 bytes of `cell` into `bytes` using a zero-allocation ASCII fast path and falling back to
    /// `scalars` for non-ASCII or grapheme clusters. Calls `onByte` for each appended byte.
    func appendCellUTF8(
        _ cell: Cell,
        to bytes: inout [UInt8],
        scalars: inout String.UnicodeScalarView,
        onByte: () -> Void = {}
    ) {
        let code = cell.scalar
        if !cell.isCluster {
            if code == 0 {
                bytes.append(0x20)
                onByte()
                return
            }
            if code < 0x80 {
                bytes.append(UInt8(truncatingIfNeeded: code))
                onByte()
                return
            }
        }
        scalars.removeAll(keepingCapacity: true)
        appendText(of: cell, to: &scalars)
        for scalar in scalars {
            for byte in scalar.utf8 {
                bytes.append(byte)
                onByte()
            }
        }
    }

    /// Escapes every RE2 metacharacter so a plain-text search matches literally with zero regex surprises.
    private static func escapeRegexLiteral(_ text: String) -> String {
        let metacharacters: Set<Character> = Set(#"\.+*?()|[]{}^$"#)
        return text.reduce(into: "") { result, ch in
            if metacharacters.contains(ch) { result.append("\\") }
            result.append(ch)
        }
    }
}
