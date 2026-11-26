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
    @State private var keeping: Task<Void, Never>?
    /// Whether the window is the key one: the edits are kept when it is no longer (the focus went elsewhere).
    @Environment(\.appearsActive) private var appearsActive

    init(entry: VaultEntry, model: PasswordsModel, editing: Bool = false) {
        self.model = model
        var draft = EntryDraft(entry)
        if editing { draft.beginEditing() }
        _draft = State(initialValue: draft)
        _editing = State(initialValue: editing)
    }

    /// The generator's recipe: twenty characters of every class.
    static let recipe = PasswordRecipe(length: 20, classes: CharacterClass.allCases)
    /// Memorable Diceware passphrase recipe: five words separated by hyphens with a digit.
    static let passphraseRecipe = PassphraseRecipe(words: 5, separator: "-", capitalize: false, includeNumber: true)

    var body: some View {
        Form {
            Section {
                PasswordEntryHeader(
                    entry: $draft.entry,
                    editing: editing,
                    canSave: draft.canSave(now: Runtime.live.now()) || !draft.isChanged,
                    edit: beginEditing,
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
            PasswordAttachmentsSection(
                attachments: draft.entry.attachments ?? [],
                editing: editing,
                add: { draft.entry.addAttachment($0) },
                remove: { draft.entry.removeAttachment($0) }
            )
            if editing { addField }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: Design.Size.settingsPage)
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: editing)
        // Edits are kept as they are made (n138: a card filled in and left without Done was lost): a moment after the
        // last change, and when the page goes away.
        .onChange(of: draft.entry) {
            // Noted at once: kept before the vault locks and when Sunset loses focus, whatever comes first.
            if draft.canSave(now: Runtime.live.now()) { model.noteEdit(draft.entry) }
            keepSoon()
        }
        .onChange(of: appearsActive) { _, active in if !active { keep() } }
        .onDisappear { keep() }
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
                        generatePassphrase: { draft.generatePassphrase(into: field.id, recipe: Self.passphraseRecipe) },
                        readCode: { code in draft.setUp(code) },
                        remove: { draft.entry.remove(field.id) },
                        edits: FieldEdits { draft.entry.apply($0, to: field.id) }
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

    /// Nothing to read: no field holds a value, no note, and no attachments.
    private var isBlank: Bool {
        draft.entry.note.isEmpty
            && (draft.entry.attachments?.isEmpty ?? true)
            && draft.entry.sections.allSatisfy { $0.fields.allSatisfy(\.value.isEmpty) }
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
            if !editing { beginEditing() }
            Feedback.give(.done("One-time code read"))
        }
    }

    private func beginEditing() {
        draft.beginEditing()
        editing = true
    }

    /// Back to the entry as editing began, kept again when edits were kept meanwhile.
    private func cancel() {
        if let back = draft.cancelEditing(), (try? model.save(back)) != nil { draft.saved() }
        editing = false
    }

    private func done() {
        if draft.isChanged {
            draft.recordSecretHistory(now: Runtime.live.now())
            guard (try? model.save(draft.entry)) != nil else { return }
            draft.saved()
        }
        editing = false
    }

    /// Keeps the edits when they can be kept (a required field left empty keeps them from it).
    private func keep() {
        keeping?.cancel()
        guard draft.canSave(now: Runtime.live.now()) else { return }
        draft.recordSecretHistory(now: Runtime.live.now())
        guard (try? model.save(draft.entry)) != nil else { return }
        draft.saved()
    }

    private func keepSoon() {
        keeping?.cancel()
        keeping = Runtime.live.task { @MainActor in
            guard await Runtime.live.sleep(for: Self.keepAfter) else { return }
            keep()
        }
    }

    /// How long after the last change edits are kept.
    static let keepAfter = Duration.milliseconds(700)
}
