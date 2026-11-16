import SunsetShell
import SwiftUI

/// The question before quitting (web step q): what would be lost, each row showing its tab when clicked (which cancels the quit), Cancel, Quit,
/// and "Don't ask again". With unsaved edits among them, Return is Save All and Quit (roadmap 0023 step M-d).
struct QuitSheet: View {
    let gate: QuitGate
    @State private var dontAsk = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text("Quit Sunset?").font(Design.Text.title)
            if gate.losses.isEmpty {
                Text("Nothing would be lost.").foregroundStyle(.secondary)
            } else {
                Text("Quitting now would lose:").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    ForEach(gate.losses) { loss in
                        Button {
                            gate.show(loss)
                        } label: {
                            Label(loss.text, systemImage: loss.symbol).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .help(loss.pane == nil ? "" : "Show it (the quit is cancelled)")
                    }
                }
            }
            // Unsaved edits are asked about whatever the setting says: the box is offered only when it would change something.
            if gate.asksBySetting { Toggle("Don't ask again", isOn: $dontAsk) }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { gate.answer(quit: false) }.keyboardShortcut(.cancelAction)
                if gate.hasUnsavedDocuments {
                    // Edits can be saved first: that is the answer of Return, and quitting without is said as what it is.
                    Button("Quit Without Saving") { gate.answer(quit: true, dontAskAgain: dontAsk) }
                    Button("Save All and Quit") { gate.saveAllAndQuit(dontAskAgain: dontAsk) }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Quit") { gate.answer(quit: true, dontAskAgain: dontAsk) }.keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(Design.Space.xxl)
        .frame(width: gate.hasUnsavedDocuments ? 480 : 420)
    }
}
