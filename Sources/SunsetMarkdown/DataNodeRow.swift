import SunsetDocuments
import SunsetShell
import SwiftUI

/// A node of a data tree: its key, then its value or how many it holds.
struct DataNodeRow: View {
    let node: DataTree

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Space.s) {
            Text(node.key).foregroundStyle(.secondary)
            value
        }
        .font(Design.Text.detail.monospaced())
        .textSelection(.enabled)
    }

    @ViewBuilder private var value: some View {
        switch node.value {
            case .object(let count): Text(count == 1 ? "{1 key}" : "{\(count) keys}").foregroundStyle(.tertiary)
            case .array(let count): Text(count == 1 ? "[1 item]" : "[\(count) items]").foregroundStyle(.tertiary)
            case .string(let text): Text("\"\(text)\"").foregroundStyle(.green)
            case .number(let number): Text(number).foregroundStyle(.blue)
            case .bool(let flag): Text(flag ? "true" : "false").foregroundStyle(.orange)
            case .null: Text("null").foregroundStyle(.tertiary)
        }
    }
}
