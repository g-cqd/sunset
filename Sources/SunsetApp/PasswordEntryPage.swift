import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// An entry, edited on its page (roadmap 0092 B): its title, then each section's fields in a native list whose rows are
/// reordered by dragging; a secret field shows dots only, copied or filled with a generated password from its menu; a
/// problem said under its field. Saved or put back; a required field left empty keeps it from being saved.
struct PasswordEntryPage: View {
    let model: PasswordsModel
    @State private var draft: EntryDraft

    init(entry: VaultEntry, model: PasswordsModel) {
        self.model = model
        _draft = State(initialValue: EntryDraft(entry))
    }

    /// The generator's recipe: twenty characters of every class.
    static let recipe = PasswordRecipe(length: 20, classes: CharacterClass.allCases)

    var body: some View {
        List {
            Section {
                TextField("Title", text: $draft.entry.title).font(Design.Text.title).textFieldStyle(.plain)
            }
            ForEach(draft.entry.sections) { section in
                Section(section.name) {
                    ForEach(section.fields) { field in
                        PasswordFieldRow(
                            field: field,
                            problem: problem(field),
                            value: binding(field.id),
                            generate: { draft.generate(into: field.id, recipe: Self.recipe) },
                            remove: { draft.entry.remove(field.id) }
                        )
                    }
                    .onMove { draft.move(in: section.id, from: $0, to: $1) }
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { buttons }
    }

    private var buttons: some View {
        HStack(spacing: Design.Space.s) {
            Menu("Add Field") {
                ForEach(EntryDraft.addable, id: \.name) { item in
                    Button(item.name) { draft.add(item.kind) }
                }
            }
            .fixedSize()
            Spacer(minLength: 0)
            Button("Revert") { draft.revert() }.disabled(!draft.isChanged)
            Button("Save") { save() }
                .keyboardShortcut("s")
                .disabled(!draft.canSave(now: Runtime.live.now()))
        }
        .padding(Design.Space.m)
        .background(.bar)
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

    private func save() {
        guard (try? model.save(draft.entry)) != nil else { return }
        draft.saved()
    }
}
