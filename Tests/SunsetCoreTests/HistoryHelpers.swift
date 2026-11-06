import AemiTestKit
import Testing

@testable import SunsetCore

func terminal(_ text: String, _ columns: Int = 10, _ rows: Int = 4, limit: Int = 10_000) -> Terminal {
    var terminal = Terminal(columns: columns, rows: rows, scrollbackLimit: limit)
    terminal.feed(text)
    return terminal
}

func history(_ terminal: Terminal) -> [String] {
    (0 ..< terminal.screen.scrollbackCount).map { terminal.screen.scrollbackText(line: $0) }
}

func rows(_ terminal: Terminal) -> [String] {
    (0 ..< terminal.screen.rows).map { terminal.screen.text(row: $0) }
}

/// The text of the whole buffer as logical lines (rows joined where a line wrapped), without trailing empty lines.
func logicalLines(_ screen: Screen) -> [String] {
    var lines: [String] = []
    var current = ""
    func finish(_ wrapped: Bool, _ text: String) {
        current += text
        if !wrapped {
            lines.append(trimmed(current))
            current = ""
        }
    }
    for line in 0 ..< screen.scrollbackCount {
        var text = ""
        for column in 0 ..< screen.columns {
            let cell = screen.scrollbackCell(line: line, column: column)
            if cell.width == .spacerTail || cell.width == .spacerHead { continue }
            text.unicodeScalars.append(Unicode.Scalar(cell.scalar == 0 ? 0x20 : cell.scalar) ?? "?")
        }
        let wrapped = screen.isScrollbackWrapped(line: line)
        finish(wrapped, wrapped ? text : trimmed(text))
    }
    for row in 0 ..< screen.rows {
        var text = ""
        for column in 0 ..< screen.columns {
            let cell = screen.cell(row: row, column: column)
            if cell.width == .spacerTail || cell.width == .spacerHead { continue }
            text.unicodeScalars.append(Unicode.Scalar(cell.scalar == 0 ? 0x20 : cell.scalar) ?? "?")
        }
        let wrapped = screen.isWrapped(row: row)
        finish(wrapped, wrapped ? text : trimmed(text))
    }
    if !current.isEmpty { lines.append(trimmed(current)) }
    while lines.last == "" { lines.removeLast() }
    return lines
}

func trimmed(_ text: String) -> String {
    var text = text
    while text.last == " " { text.removeLast() }
    return text
}
