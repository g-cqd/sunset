import Testing

@testable import SunsetCore

/// A deliberately naive model of the text-only subset (print with autowrap, CR, LF, BS, HT), one character at a time with no fast path, to hold the
/// screen's row-at-a-time ASCII path against.
private struct NaiveScreen {
    let columns: Int
    let rows: Int
    var cells: [[Character]]
    var x = 0
    var y = 0
    var pending = false

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        cells = Array(repeating: Array(repeating: " ", count: columns), count: rows)
    }

    mutating func lineFeed() {
        if y == rows - 1 {
            cells.removeFirst()
            cells.append(Array(repeating: " ", count: columns))
        } else {
            y += 1
        }
    }

    mutating func feed(_ byte: UInt8) {
        switch byte {
            case 0x0D:
                x = 0
                pending = false
            case 0x0A:
                lineFeed()
                pending = false
            case 0x08:
                x = max(0, x - 1)
                pending = false
            case 0x09:
                var next = x + 1
                while next < columns - 1, next % 8 != 0 { next += 1 }
                x = min(next, columns - 1)
                pending = false
            default:
                if pending {
                    x = 0
                    lineFeed()
                    pending = false
                }
                cells[y][x] = Character(Unicode.Scalar(byte))
                if x == columns - 1 { pending = true } else { x += 1 }
        }
    }

    var lines: [String] {
        cells.map { row in
            var text = String(row)
            while text.last == " " { text.removeLast() }
            return text
        }
    }
}

@Suite("Screen: differential against a naive model") struct ScreenDifferentialTests {
    @Test func `printable ASCII with CR LF BS and TAB matches the naive model, however the input is cut`() {
        var random = SplitMix64(state: 11)
        let pool: [UInt8] = Array(0x20 ... 0x7E) + [0x0D, 0x0A, 0x08, 0x09, 0x0A, 0x0D]
        for _ in 0 ..< 400 {
            let columns = 1 + random.below(30)
            let rows = 1 + random.below(8)
            let input = (0 ..< random.below(400)).map { _ in pool[random.below(pool.count)] }
            var naive = NaiveScreen(columns: columns, rows: rows)
            for byte in input { naive.feed(byte) }

            var terminal = Terminal(columns: columns, rows: rows)
            var offset = 0
            while offset < input.count {
                let end = min(input.count, offset + 1 + random.below(40))
                input[offset ..< end].withUnsafeBufferPointer { terminal.feed($0.span) }
                offset = end
            }
            let lines = (0 ..< rows).map { terminal.screen.text(row: $0) }
            #expect(lines == naive.lines, "\(columns)x\(rows) \(input)")
            #expect([terminal.screen.cursorRow, terminal.screen.cursorColumn] == [naive.y, naive.x])
        }
    }
}
