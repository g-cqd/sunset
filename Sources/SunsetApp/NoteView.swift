import SunsetShell
import SwiftUI

/// The editor of a note. A click in it gives its pane the keyboard, as a click in a terminal does.
struct NoteView: View {
    @Bindable var note: NoteContent
    let focused: Bool
    @FocusState private var editing: Bool

    var body: some View {
        TextEditor(text: $note.text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(.background.opacity(Design.Fill.noteBackground))
            .focused($editing)
            .onChange(of: editing) { _, now in if now { note.onFocusRequest() } }
            .onChange(of: focused, initial: true) { _, now in if now != editing { editing = now } }
    }
}
