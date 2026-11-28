import MarkdownLookKit
import SunsetDocuments
import SunsetShell
import SwiftUI

/// A CSV or TSV document drawn as a table: its first row as the headers, every column sortable, the rest scrolling. Drawn
/// again from the text as it is edited (beside it, or after Show Source).
struct TableDocumentView: View {
    let content: DocumentContent
    @State private var order: [KeyPathComparator<TableRow>] = []

    var body: some View {
        let source = content.document.source
        let table = TableText(source.text, separator: TableText.separator(path: content.file?.path), limit: 10_000)
        let width = table.rows.map(\.count).max() ?? 0
        let headers = table.rows.first.map { first in (0 ..< width).map { $0 < first.count ? first[$0] : "" } } ?? []
        let rows = table.rows.dropFirst().enumerated().map { TableRow(id: $0.offset, cells: $0.element) }
        VStack(alignment: .leading, spacing: 0) {
            Table(rows.sorted(using: order), sortOrder: $order) {
                TableColumnForEach(0 ..< width, id: \.self) { column in
                    TableColumn(
                        headers[column].isEmpty ? "\(column + 1)" : headers[column],
                        sortUsing: TableRow.by(column)
                    ) { row in
                        Text(row.cell(column)).textSelection(.enabled)
                    }
                }
            }
            if table.total > table.rows.count {
                Text("The first \(table.rows.count) of \(table.total) rows")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
                    .padding(Design.Space.s)
            }
        }
        .id(source.revision)
    }
}
