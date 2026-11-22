import SunsetShell
import SwiftUI

/// A page's dialog: a panel in the middle of its pane, over a veil that keeps the page from being used until it is
/// answered. The page's words are plain text. Return answers OK, Escape cancels.
struct PageDialogPanel: View {
    let dialog: PageDialog
    let silence: () -> Void
    @State private var typed = ""
    @FocusState private var typing: Bool

    var body: some View {
        PagePanel {
            Text.sentence(dialog.title, code: [dialog.host]).font(Design.Text.body.weight(.semibold))
            ScrollView {
                Text(verbatim: dialog.message)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .bouncesOnlyWhenScrolling()
            .frame(maxHeight: Design.Size.dialogMessage)
            .fixedSize(horizontal: false, vertical: true)
            if case .prompt = dialog.kind {
                TextField("", text: $typed).textFieldStyle(.roundedBorder).focused($typing)
            }
            HStack {
                if dialog.offersSilence {
                    Button("Stop This Page's Dialogs", action: silence)
                }
                Spacer()
                if dialog.kind != .alert {
                    Button("Cancel") { dialog.answer(.cancel) }.keyboardShortcut(.cancelAction)
                }
                Button("OK") { dialog.answer(.ok(reply)) }.keyboardShortcut(.defaultAction)
            }
        }
        .onAppear {
            if case .prompt(let text) = dialog.kind {
                typed = text
                typing = true
            }
        }
    }

    /// What a prompt was answered with; nothing for the others.
    private var reply: String? {
        if case .prompt = dialog.kind { return typed }
        return nil
    }
}
