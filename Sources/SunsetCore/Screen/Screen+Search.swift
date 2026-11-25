import AemiRegex

/// Plain-text and RE2 regular-expression search across a terminal's entire scrollback history and live screen
/// (T-3 / roadmap 0026).
///
/// Wrapped physical rows are joined into logical lines before matching so a query finds text split across a terminal
/// wrap boundary, and every byte offset in the logical line maps back cleanly to `(absoluteLine, column)` — covering
/// wide characters (2 columns) and grapheme clusters accurately.
extension Screen {
    /// Searches the entire scrollback + live screen for `query`, returning matches in top-to-bottom order.
    /// Uses `AemiRegex.Pattern` (RE2 linear-time engine, ReDoS-safe) for both regular-expression and plain-text queries
    /// (plain text is escaped into a literal pattern, with `(?i)` applied when `matchCase == false`).
    public func search(_ query: SearchQuery, limit: Int = SearchResult.defaultLimit) -> SearchResult {
        guard !query.text.isEmpty, limit > 0 else { return .empty }
        let source = query.isRegex ? query.text : Self.escapeRegexLiteral(query.text)
        let effective = query.matchCase ? source : "(?i)" + source
        let pattern: Pattern
        do {
            pattern = try Pattern(effective)
        } catch {
            return SearchResult(matches: [], error: "\(error)")
        }
        return collectMatches(for: pattern, limit: limit)
    }

    private func collectMatches(for pattern: Pattern, limit: Int) -> SearchResult {
        let total = absoluteLineCount
        guard total > 0 else { return .empty }

        var matches: [SearchMatch] = []
        var truncated = false
        var line = 0
        var bytes: [UInt8] = []
        var positions: [(line: Int, startColumn: Int, endColumn: Int)] = []

        while line < total {
            bytes.removeAll(keepingCapacity: true)
            positions.removeAll(keepingCapacity: true)

            // Assemble one logical line across any wrapped physical rows.
            var endLine = line
            while true {
                appendPhysicalLine(endLine, bytes: &bytes, positions: &positions)
                let wrapped = isAbsoluteWrapped(line: endLine) && endLine + 1 < total
                if !wrapped {
                    // Drop trailing spaces on the final physical row of a logical line (matching `Screen.text(of:)`).
                    while bytes.last == 0x20, positions.last != nil {
                        bytes.removeLast()
                        positions.removeLast()
                    }
                    break
                }
                endLine += 1
            }

            if !bytes.isEmpty {
                pattern.forEachMatch(in: bytes) { match in
                    guard !match.range.isEmpty,
                        match.range.lowerBound < positions.count,
                        match.range.upperBound <= positions.count
                    else { return true }
                    let first = positions[match.range.lowerBound]
                    let last = positions[match.range.upperBound - 1]
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

    private func appendPhysicalLine(
        _ line: Int,
        bytes: inout [UInt8],
        positions: inout [(line: Int, startColumn: Int, endColumn: Int)]
    ) {
        forEachAbsoluteCell(on: line) { cell, startColumn, endColumn in
            var scalars = String.UnicodeScalarView()
            appendText(of: cell, to: &scalars)
            for scalar in scalars {
                for byte in scalar.utf8 {
                    bytes.append(byte)
                    positions.append((line: line, startColumn: startColumn, endColumn: endColumn))
                }
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
