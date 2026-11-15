import SunsetMarkdown
import SwiftUI

/// The View menu's items for the document in front (roadmap 0023 step M-c): off while another kind of pane has the keyboard.
struct DocumentCommands: View {
    let document: DocumentContent?

    var body: some View {
        Button(document?.mode == .source ? "Show Rendered" : "Show Source") { document?.toggleMode() }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(document?.canRender != true)
        Button("Show Beside") { document?.showBeside() }
            .keyboardShortcut("e", modifiers: [.command, .option])
            .disabled(document?.canRender != true)
    }
}
