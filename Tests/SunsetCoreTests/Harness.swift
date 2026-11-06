import Testing

@testable import SunsetCore

/// A terminal fed text, read back as rows of text (blank cells as spaces, trailing spaces trimmed) and the cursor position.
struct Harness {
    var terminal: Terminal
    init(_ columns: Int = 10, _ rows: Int = 4) { terminal = Terminal(columns: columns, rows: rows) }

    mutating func feed(_ text: String) { terminal.feed(text) }
    var screen: Screen { terminal.screen }
    var lines: [String] { (0 ..< screen.rows).map { screen.text(row: $0) } }
    var cursor: [Int] { [screen.cursorRow, screen.cursorColumn] }
}

func make(_ text: String, _ columns: Int = 10, _ rows: Int = 4) -> Harness {
    var harness = Harness(columns, rows)
    harness.feed(text)
    return harness
}
