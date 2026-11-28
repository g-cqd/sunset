/// A CSV or TSV text read as rows of cells (RFC 4180: a quoted cell may hold the separator, line breaks and doubled
/// quotes). Lenient: a stray quote is kept as text, a short row stays short. At most `limit` rows are kept; `total` says
/// how many there were.
public struct TableText: Sendable, Equatable {
    public var rows: [[String]]
    public var total: Int

    /// - Complexity: O(the text), read once.
    public init(_ text: String, separator: Character = ",", limit: Int = 10_000) {
        var rows: [[String]] = []
        var row: [String] = []
        var cell = ""
        var quoted = false
        var total = 0
        var characters = text.makeIterator()
        var pending: Character?
        func endRow() {
            row.append(cell)
            cell = ""
            if !(row.count == 1 && row[0].isEmpty) {
                total += 1
                if rows.count < limit { rows.append(row) }
            }
            row = []
        }
        while let character = pending ?? characters.next() {
            pending = nil
            if quoted {
                if character == "\"" {
                    let next = characters.next()
                    if next == "\"" {
                        cell.append("\"")
                    } else {
                        quoted = false
                        pending = next
                    }
                } else {
                    cell.append(character)
                }
                continue
            }
            switch character {
                case "\"" where cell.isEmpty: quoted = true
                case separator:
                    row.append(cell)
                    cell = ""
                case "\n", "\r\n", "\r": endRow()
                default: cell.append(character)
            }
        }
        if !cell.isEmpty || !row.isEmpty { endRow() }
        self.rows = rows
        self.total = total
    }

    /// The separator a file's name says: a tab for `.tsv`, else a comma.
    public static func separator(path: String?) -> Character {
        path?.lowercased().hasSuffix(".tsv") == true ? "\t" : ","
    }
}
