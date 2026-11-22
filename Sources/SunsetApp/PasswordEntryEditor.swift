import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// An open entry of the Passwords section, edited in place (roadmap 0092 B): its title; each field's value, a concealed
/// one hidden until shown, with a password generated for it on request; a problem said under its field; fields added by
/// kind, removed from their menu. Saved or put back; a required field left empty keeps it from being saved.
struct PasswordEntryEditor: View {
    let model: PasswordsModel
    @State private var draft: EntryDraft
    @State private var revealed: Set<EntryField.ID> = []

    init(entry: VaultEntry, model: PasswordsModel) {
        self.model = model
        _draft = State(initialValue: EntryDraft(entry))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            TextField("Title", text: $draft.entry.title).textFieldStyle(.roundedBorder)
            ForEach(draft.entry.sections) { section in
                ForEach(section.fields) { field in
                    PasswordFieldRow(
                        field: field,
                        problem: problem(field),
                        isRevealed: revealed.contains(field.id),
                        value: binding(field.id),
                        reveal: { toggleReveal(field.id) },
                        generate: { draft.generate(into: field.id, recipe: Self.recipe) },
                        remove: { draft.entry.remove(field.id) }
                    )
                }
            }
            buttons
        }
        .padding(.leading, Design.Size.glyphFrame + Design.Space.s)
    }

    /// The generator's recipe: twenty characters of every class.
    static let recipe = PasswordRecipe(length: 20, classes: CharacterClass.allCases)

    private var buttons: some View {
        HStack(spacing: Design.Space.s) {
            Menu("Add Field") {
                ForEach(EntryDraft.addable, id: \.name) { item in
                    Button(item.name) { draft.add(item.kind) }
                }
            }
            .fixedSize()
            Spacer(minLength: 0)
            if draft.isChanged {
                Button("Revert") { draft.revert() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!draft.canSave(now: Runtime.live.now()))
            }
        }
        .controlSize(.small)
    }

    private func binding(_ field: EntryField.ID) -> Binding<String> {
        Binding(
            get: { draft.entry.sections.lazy.flatMap(\.fields).first { $0.id == field }?.value ?? "" },
            set: { draft.entry.set(field, $0) }
        )
    }

    private func problem(_ field: EntryField) -> String? {
        draft.entry.problems(now: Runtime.live.now()).first { $0.field == field.id }
            .map { FieldWording.problem($0.constraint) }
    }

    private func toggleReveal(_ field: EntryField.ID) {
        if revealed.contains(field) { revealed.remove(field) } else { revealed.insert(field) }
    }

    private func save() {
        guard (try? model.save(draft.entry)) != nil else { return }
        draft.saved()
    }
}
