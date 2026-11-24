import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// One field of an entry on its page, a row of the form: its name, then its value. Read, the value (a secret one as dots,
/// never its characters), copied by its button (never a click on the row, n129). Edited, a field of the form (a secret one a secure
/// field), its menu to generate a password into it or remove it. A problem with its value under it.
struct PasswordFieldRow: View {
    let field: EntryField
    let editing: Bool
    let problem: String?
    @Binding var value: String
    let generate: () -> Void
    /// A code read from a QR code's picture (the clipboard's, or a file's) sets the entry up.
    let readCode: @MainActor (OneTimeCodeURI) -> Void
    let remove: () -> Void
    let edits: FieldEdits
    /// A secret shown in clear by its eye button, until the page is left (n101).
    @State var revealed = false
    /// Its name, kind and secrecy being edited in a sheet (t334).
    @State var editingField = false
    @State private var hovered = false
    @State private var feedback = FeedbackCue()
    @Environment(\.runtime) private var runtime

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            if editing { edited } else { read }
            if let problem {
                Text(problem).font(Design.Text.detail).foregroundStyle(.orange)
            }
        }
    }

    private var read: some View {
        LabeledContent(field.name) {
            HStack(spacing: Design.Space.s) {
                if field.kind == .oneTimeCode {
                    OneTimeCodeValue(field: OneTimeCodeField(value))
                } else {
                    Text(field.isSecret && !revealed ? Self.dots : value)
                        // A secret in a monospaced face, as a terminal shows it: 0 and O, l and 1 apart (n103).
                        .font(field.isSecret ? Design.Text.body.monospaced() : Design.Text.body)
                        .lineLimit(field.kind == .multiline ? nil : 1)
                        .truncationMode(.middle)
                        .foregroundStyle(.primary)
                        .textSelection(.disabled)
                    if field.isSecret { revealButton }
                }
                // Copying is its button's, not the whole field's (n129): shown under the pointer, and while it says it copied;
                // the glyph becomes a check for a moment (n111).
                RowGlyphButton(help: feedback.cue?.announcement ?? "Copy \(field.name)", action: copy) {
                    FeedbackGlyph(symbol: "doc.on.doc", cue: feedback.cue, shakes: feedback.shakes)
                }
                .opacity(hovered || feedback.cue != nil ? 1 : 0)
                .accessibilityLabel("Copy \(field.name)")
            }
        }
        .onHover { hovered = $0 }
        .animation(.snappy(duration: 0.12), value: hovered)
        .inkedContextMenu { Button("Copy \(field.name)", action: copy) }
    }

    /// The clipboard's QR code picture read.
    func pasteCode() {
        guard let image = QRCodeImages.image() else {
            Feedback.give(.blocked("No picture on the clipboard"))
            return
        }
        Runtime.live.task { @MainActor in
            if let code = await QRCodeImages.code(in: image) { readCode(code) }
        }
    }

    /// "Required" for a field that must be filled, else "Optional".
    var prompt: String {
        field.constraints.contains(.required) ? "Required" : "Optional"
    }

    var axis: Axis {
        field.kind == .multiline ? .vertical : .horizontal
    }

    /// The value; a One-Time Code field's code now, never its secret. Said as every copy is (`FeedbackCue`).
    private func copy() {
        let outcome: ActionFeedback
        if field.kind == .oneTimeCode {
            guard let code = OneTimeCodeField(value)?.code(at: runtime.now()) else { return }
            outcome = Clipboard.copy(code, concealed: true, what: "Code copied")
        } else {
            outcome = Clipboard.copy(value, concealed: field.isSecret, what: "\(field.name) copied")
        }
        feedback.show(outcome)
        runtime.task {
            await runtime.sleep(for: ActionFeedback.shown)
            feedback.clear(outcome)
        }
    }

    /// A secret's stand-in: always as long, whatever its length.
    private static let dots = String(repeating: "\u{2022}", count: 10)
}
