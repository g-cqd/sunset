import SunsetShell
import SwiftUI

/// The question before unsaved edits close (R6, roadmap 0023 step M-d): Save (Return), Don't Save (Cmd-D, as everywhere on
/// the Mac), Cancel (Escape). With several documents they are named, and Save writes them all.
struct UnsavedSheet: View {
    let tabs: TabsModel
    let question: UnsavedQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text(question.title).font(Design.Text.title).fixedSize(horizontal: false, vertical: true)
            Text(question.detail).foregroundStyle(.secondary)
            if question.documents.count > 1 {
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    ForEach(question.documents, id: \.id) { document in
                        Label(document.title, systemImage: "doc.text")
                    }
                }
            }
            HStack {
                Button("Don\u{2019}t Save", role: .destructive) { tabs.answerUnsaved(.discard) }
                    .keyboardShortcut("d", modifiers: .command)
                Spacer()
                Button("Cancel", role: .cancel) { tabs.answerUnsaved(.cancel) }.keyboardShortcut(.cancelAction)
                Button(question.saveLabel) { tabs.answerUnsaved(.save) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Space.xxl)
        .frame(width: 420)
    }
}
