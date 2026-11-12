import SunsetShell
import SwiftUI

/// The question before quitting (web step q): what would be lost, each row showing its tab when clicked (which cancels the quit), Cancel, Quit,
/// and "Don't ask again".
struct QuitSheet: View {
    let gate: QuitGate
    @State private var dontAsk = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quit Sunset?").font(Design.Text.title)
            if gate.losses.isEmpty {
                Text("Nothing would be lost.").foregroundStyle(.secondary)
            } else {
                Text("Quitting now would lose:").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
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
            Toggle("Don't ask again", isOn: $dontAsk)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { gate.answer(quit: false) }.keyboardShortcut(.cancelAction)
                Button("Quit") { gate.answer(quit: true, dontAskAgain: dontAsk) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Space.xxl)
        .frame(width: 420)
    }
}
