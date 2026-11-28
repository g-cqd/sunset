import Foundation

/// A row of a table document, its cells by column.
struct TableRow: Identifiable {
    let id: Int
    let cells: [String]

    func cell(_ column: Int) -> String {
        column < cells.count ? cells[column] : ""
    }

    /// Sorts on `column`: numbers as numbers, the rest as text compared as Finder does.
    static func by(_ column: Int) -> KeyPathComparator<TableRow> {
        KeyPathComparator(\TableRow.self, comparator: CellOrder(column: column))
    }
}
