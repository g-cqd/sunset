import SunsetShell
import SwiftUI

/// Entering a recovery code: the key it holds is kept in place of none; in place of another only once the person has
/// confirmed, because what the present key sealed would no longer open.
struct RecoveryCodeSheet: View {
    let storage: StorageSettings
    @State private var code = ""
    @State private var result: StorageSettings.Entered?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text("Enter a recovery code").font(.headline)
            Text("Eleven groups of five letters and digits. Spaces, dashes and the case do not matter.")
                .font(Design.Text.detail).foregroundStyle(.secondary)
            TextField("Recovery code", text: $code, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2 ... 3)
                .textFieldStyle(.roundedBorder)
                .onChange(of: code) { _, _ in result = nil }
            if let sentence {
                Text(sentence).foregroundStyle(result == .kept || result == .same ? .secondary : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Button(done ? "Done" : "Cancel", role: done ? nil : .cancel) { dismiss() }
                    .keyboardShortcut(done ? .defaultAction : .cancelAction)
                if result == .differs {
                    Button("Replace the Key", role: .destructive) {
                        result = storage.enter(code: code, replacing: true)
                    }
                } else if !done {
                    Button("Enter") { result = storage.enter(code: code, replacing: false) }
                        .keyboardShortcut(.defaultAction)
                        .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(Design.Space.xl)
        .frame(width: 440)
    }

    private var done: Bool {
        result == .kept || result == .same
    }

    private var sentence: String? {
        switch result {
            case .kept: "The key is kept. Sunset uses it from its next start: quit and open it again."
            case .same: "This is the key this Mac already has. Nothing changed."
            case .differs:
                "Another key is kept on this Mac. Replacing it means that what it sealed here (documents, the session, the "
                    + "history) no longer opens, unless you have its own recovery code."
            case .notACode: "That is not a recovery code: a mistyped one fails its check."
            case .refused: "The key could not be kept: the Keychain refused."
            case nil: nil
        }
    }
}
