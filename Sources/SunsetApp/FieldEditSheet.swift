import SunsetCredentials
import SunsetShell
import SwiftUI

/// A field's name, kind and secrecy, edited apart from its value (the owner, 2026-11-23, t334). A kind its value does not
/// fit is asked about first: keep the value in a new field beside it, or leave it as written. Nothing changes until Save;
/// Cancel leaves the field as it was.
struct FieldEditSheet: View {
    let field: EntryField
    let save: (FieldChange) -> Void
    @State private var change: FieldChange
    /// A kind chosen that the value does not fit, waiting for the person's answer, and why it does not.
    @State private var asked: (kind: FieldKind, why: String)?
    @Environment(\.dismiss) private var dismiss

    init(field: EntryField, save: @escaping (FieldChange) -> Void) {
        self.field = field
        self.save = save
        _change = State(initialValue: FieldChange(name: field.name, kind: field.kind, secret: field.isSecret))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text("Edit Field").font(Design.Text.title)
            Form {
                TextField("Name", text: $change.name)
                Picker("Kind", selection: kind) {
                    ForEach(EntryDraft.addable, id: \.name) { Text($0.name).tag($0.kind) }
                    if !EntryDraft.addable.contains(where: { $0.kind == field.kind }) {
                        Text("As Made").tag(field.kind)
                    }
                }
                Toggle("Secret", isOn: $change.secret)
                    .settingSwitch()
                if change.keepingOld {
                    Text("Its value will be kept in a new field, \u{201C}\(field.name) (before)\u{201D}.")
                        .font(Design.Text.detail)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") {
                    save(change)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(change.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Design.Space.l)
        .frame(width: 380)
        .confirmationDialog(
            "Change \u{201C}\(field.name)\u{201D} to \(asked.map { Self.name(of: $0.kind) } ?? "")?",
            isPresented: Binding(get: { asked != nil }, set: { if !$0 { asked = nil } }),
            presenting: asked
        ) { pending in
            Button("Keep the Value in a New Field") { choose(pending.kind, keepingOld: true) }
            Button("Change and Leave It as It Is") { choose(pending.kind, keepingOld: false) }
            Button("Cancel", role: .cancel) {}
        } message: { pending in
            Text("Its value does not fit: \(pending.why). Nothing is lost if you keep it in a new field.")
        }
    }

    /// The kind chosen: at once when the value fits it, else asked about.
    private var kind: Binding<FieldKind> {
        Binding(
            get: { change.kind },
            set: { chosen in
                if case .loses(let why) = chosen.fit(field.value) {
                    asked = (chosen, why)
                } else {
                    choose(chosen, keepingOld: false)
                }
            }
        )
    }

    /// A new kind brings its own secrecy (a password is secret); the switch can still change it.
    private func choose(_ kind: FieldKind, keepingOld: Bool) {
        if kind != change.kind { change.secret = kind.isConcealed }
        change.kind = kind
        change.keepingOld = keepingOld
        asked = nil
    }

    private static func name(of kind: FieldKind) -> String {
        EntryDraft.addable.first { $0.kind == kind }?.name.lowercased() ?? "another kind"
    }
}
