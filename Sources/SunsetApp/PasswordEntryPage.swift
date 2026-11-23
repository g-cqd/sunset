import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI
import UniformTypeIdentifiers

/// An entry on the vault's page, laid out as a page of Settings (a grouped form, as wide as theirs, centred): a header
/// with its picture, title and kind, Edit at its end; each section's fields; its notes. Read, a field is its value (a
/// secret one as dots), copied with a click; empty ones are left out. Edited, each is a field of the form, the rows of a
/// section reordered by dragging them, removed or filled with a generated password from their menu; Done saves, Cancel
/// puts it back. A required field left empty keeps it from being saved.
struct PasswordEntryPage: View {
    let model: PasswordsModel
    @State private var draft: EntryDraft
    @State private var editing = false

    init(entry: VaultEntry, model: PasswordsModel, editing: Bool = false) {
        self.model = model
        _draft = State(initialValue: EntryDraft(entry))
        _editing = State(initialValue: editing)
    }

    /// The generator's recipe: twenty characters of every class.
    static let recipe = PasswordRecipe(length: 20, classes: CharacterClass.allCases)

    var body: some View {
        Form {
            Section {
                PasswordEntryHeader(
                    entry: $draft.entry,
                    editing: editing,
                    canSave: draft.canSave(now: Runtime.live.now()) || !draft.isChanged,
                    edit: { editing = true },
                    cancel: cancel,
                    done: done
                )
            }
            ForEach(draft.entry.sections) { section in
                fields(of: section)
            }
            if !editing, isBlank {
                Section {
                    Text("Nothing filled in yet. Edit to add its details.").foregroundStyle(.secondary)
                }
            }
            notes
            if editing { addField }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: Design.Size.settingsPage)
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: editing)
        // A QR code's picture pasted or dropped on the page sets its one-time code up (roadmap 0093 D).
        .background(QRPasteCatcher { read($0) })
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
            QRDrop.images(providers) { read($0) }
            return true
        }
    }

    @ViewBuilder private func fields(of section: EntrySection) -> some View {
        let shown = editing ? section.fields : section.fields.filter { !$0.value.isEmpty }
        if !shown.isEmpty {
            Section {
                ForEach(shown) { field in
                    PasswordFieldRow(
                        field: field,
                        editing: editing,
                        problem: problem(field),
                        value: binding(field.id),
                        generate: { draft.generate(into: field.id, recipe: Self.recipe) },
                        readCode: { code in draft.setUp(code) },
                        remove: { draft.entry.remove(field.id) }
                    )
                }
                .onMove(perform: editing ? { draft.move(in: section.id, from: $0, to: $1) } : nil)
            }
        }
    }

    @ViewBuilder private var notes: some View {
        if editing || !draft.entry.note.isEmpty {
            Section("Notes") {
                if editing {
                    TextField("Notes", text: $draft.entry.note, prompt: Text("Optional"), axis: .vertical)
                        .labelsHidden()
                        .lineLimit(3 ... 12)
                } else {
                    Text(draft.entry.note).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var addField: some View {
        Section {
            Menu {
                ForEach(EntryDraft.addable, id: \.name) { item in
                    Button(item.name) { draft.add(item.kind) }
                }
            } label: {
                Label("Add Field", systemImage: "plus")
            }
            .menuStyle(.button)
            .buttonStyle(.quiet)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    /// Nothing to read: no field holds a value, and no note.
    private var isBlank: Bool {
        draft.entry.note.isEmpty && draft.entry.sections.allSatisfy { $0.fields.allSatisfy(\.value.isEmpty) }
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

    /// Reads `image` for a one-time code, and sets the entry up with it, ready to be checked and saved.
    private func read(_ image: CGImage) {
        Runtime.live.task { @MainActor in
            guard let code = await QRCodeImages.code(in: image) else { return }
            draft.setUp(code)
            editing = true
            Feedback.give(.done("One-time code read"))
        }
    }

    private func cancel() {
        draft.revert()
        editing = false
    }

    private func done() {
        if draft.isChanged {
            guard (try? model.save(draft.entry)) != nil else { return }
            draft.saved()
        }
        editing = false
    }
}
