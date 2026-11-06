import Testing

@testable import SunsetCore

/// A deliberately naive model of the text-only subset (print with autowrap, CR, LF, BS, HT), one character at a time with no fast path, to hold the
/// screen's row-at-a-time ASCII path against.
struct NaiveScreen {
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
