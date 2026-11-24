import AemiTestKit
import Foundation
import SunsetStorage
import Testing

@testable import SunsetCredentials

/// What is written as CSV is read back as it was, for any cell (roadmap 0095 D): properties over generated tables, the smallest failing
/// table reported by the kit's shrinking. The reader's one rule beyond RFC 4180 is that a line with no cell, or one empty cell, is blank
/// and not a row; the expected table drops those the same way.
@Suite("CSV: what is written is read back")
struct CSVPropertyTests {
    /// The characters that make a cell hard: separators, quotes, every line ending, a tab, what starts a formula, an apostrophe, a space,
    /// an accent, an emoji, a character of another script. `\r\n` is one `Character` in Swift, so it is listed whole.
    static let alphabet: [Character] = [
        "a", "b", "0", " ", ",", "\"", "\n", "\r", "\r\n", "\t", "=", "+", "-", "@", "'", "é", "😀", "я"
    ]

    static var cell: AnyGenerator<String> {
        Gen.string(maxLength: 12, alphabet: alphabet)
    }
    static var table: AnyGenerator<[[String]]> {
        Gen.array(of: Gen.array(of: cell, maxCount: 5), maxCount: 8)
    }

    private func expected(_ table: [[String]]) -> [[String]] {
        table.filter { $0 != [] && $0 != [""] }
    }

    @Test func `any table, written with the app's writer, is read back, formulas kept as written`() {
        forAll(Self.table, count: 600, seed: .named("csv.roundtrip")) { table in
            let text = table.map { CSV.line($0, formulas: .keep) }.joined()
            return CSVReader.rows(text) == self.expected(table)
        }
    }

    @Test
    func
        `under the spreadsheet-safe writer a cell comes back with one apostrophe in front exactly when it began like a formula`()
    {
        forAll(Self.table, count: 400, seed: .named("csv.protect")) { table in
            let text = table.map { CSV.line($0) }.joined()
            let wanted = self.expected(table)
                .map { row in
                    row.map { cell in
                        cell.unicodeScalars.first.map { "=+-@\t\r".unicodeScalars.contains($0) } == true
                            ? "'" + cell : cell
                    }
                }
            return CSVReader.rows(text) == wanted
        }
    }

    @Test func `a line ending of any kind, between rows or at the end, makes no difference to the rows`() {
        let plain = Gen.array(
            of: Gen.array(of: Gen.string(maxLength: 6, alphabet: ["a", "b", "0", " "]), maxCount: 4),
            maxCount: 6
        )
        forAll(plain, count: 300, seed: .named("csv.endings")) { table in
            let rows = table.filter { $0 != [] && $0 != [""] }
            let joined = { (ending: String, last: Bool) in
                table.map { CSV.cellsLine($0) }.joined(separator: ending) + (last ? ending : "")
            }
            return ["\r\n", "\n", "\r"]
                .allSatisfy { ending in
                    [true, false].allSatisfy { CSVReader.rows(joined(ending, $0)) == rows }
                }
        }
    }

    @Test func `a byte-order mark in front of the file is the file's, never a cell's`() {
        forAll(Self.table, count: 200, seed: .named("csv.bom")) { table in
            let text = table.map { CSV.line($0, formulas: .keep) }.joined()
            return CSVReader.rows("\u{FEFF}" + text) == CSVReader.rows(text)
        }
    }
}

extension CSV {
    /// The cells of a row as one line with no line ending: the tests choose it.
    fileprivate static func cellsLine(_ cells: [String]) -> String {
        cells.map { cell($0, formulas: .keep) }.joined(separator: ",")
    }
}
