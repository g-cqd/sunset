import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// Popover showing prior secret values of a field (`EntryField.history`, roadmap 0092 D): concealed by default with a
/// per-row reveal eye, copy-as-secret button, and optional Restore button when editing.
struct FieldHistoryPopover: View {
    let fieldName: String
    let items: [FieldHistoryItem]
    let onRestore: ((String) -> Void)?
    @State private var revealed: Set<Int> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("\(fieldName) History")
                .font(Design.Text.title)
                .padding(.bottom, Design.Space.hair)
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Space.s) {
                    ForEach(Array(items.reversed().enumerated()), id: \.offset) { offset, item in
                        historyRow(item, index: offset)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
        .padding(Design.Space.m)
        .frame(width: 340)
    }

    private func historyRow(_ item: FieldHistoryItem, index: Int) -> some View {
        let shown = revealed.contains(index)
        return VStack(alignment: .leading, spacing: Design.Space.hair) {
            HStack(spacing: Design.Space.s) {
                Text(shown ? item.value : String(repeating: "\u{2022}", count: 10))
                    .font(Design.Text.body.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RowGlyphButton(symbol: shown ? "eye.slash" : "eye", help: shown ? "Hide" : "Show") {
                    if shown { revealed.remove(index) } else { revealed.insert(index) }
                }
                RowGlyphButton(symbol: "doc.on.doc", help: "Copy previous value") {
                    _ = Clipboard.copy(item.value, concealed: true, what: "Previous value copied")
                }
                if let onRestore {
                    Button("Restore") {
                        onRestore(item.value)
                        dismiss()
                    }
                    .buttonStyle(.quiet)
                }
            }
            Text(item.changedAt, format: .dateTime.year().month().day().hour().minute())
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
    }
}
