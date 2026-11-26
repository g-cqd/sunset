public import Foundation

/// An entry being edited (roadmap 0092 B): a copy of what is kept, changed freely, saved or put back.
public struct EntryDraft: Equatable, Sendable {
    /// What is kept.
    public private(set) var kept: VaultEntry
    /// What is being edited.
    public var entry: VaultEntry

    public init(_ kept: VaultEntry) {
        self.kept = kept
        self.entry = kept
    }

    /// The kinds a field can be added as, each with the name it is given.
    public static let addable: [(name: String, kind: FieldKind)] = [
        ("Text", .text), ("Password", .concealed), ("One-Time Code", .oneTimeCode), ("Website", .url),
        ("Email", .email), ("Phone", .phone), ("Number", .number), ("Date", .date), ("Note", .multiline)
    ]

    public var isChanged: Bool {
        entry != kept
    }

    /// Changed, and with no problem that blocks a save.
    public func canSave(now: Date) -> Bool {
        isChanged && !entry.blocksSave(now: now)
    }

    /// Records previous secret field values into each changed secret field's `history` (comparing `entry` against
    /// `kept`, roadmap 0092 D) before saving.
    public mutating func recordSecretHistory(now: Date) {
        let oldByID = Dictionary(
            uniqueKeysWithValues: kept.sections.flatMap(\.fields).map { ($0.id, $0) }
        )
        for sIdx in entry.sections.indices {
            for fIdx in entry.sections[sIdx].fields.indices {
                let field = entry.sections[sIdx].fields[fIdx]
                guard field.isSecret, let prior = oldByID[field.id], !prior.value.isEmpty, prior.value != field.value
                else { continue }
                var list = field.history ?? []
                if list.last?.value != prior.value {
                    list.append(FieldHistoryItem(value: prior.value, changedAt: now))
                    if list.count > EntryField.historyLimit { list.removeFirst(list.count - EntryField.historyLimit) }
                    entry.sections[sIdx].fields[fIdx].history = list
                }
            }
        }
    }

    /// What is kept is now what was edited.
    public mutating func saved() {
        kept = entry
    }

    public mutating func revert() {
        entry = kept
    }

    /// The entry as it was when editing began: edits are kept as they are made (n138), and Cancel goes back to it.
    public private(set) var began: VaultEntry?

    public mutating func beginEditing() {
        began = kept
    }

    /// Back to the entry as editing began; returns it when it must be kept again (edits were kept since), nil otherwise.
    public mutating func cancelEditing() -> VaultEntry? {
        guard let began else {
            revert()
            return nil
        }
        self.began = nil
        entry = began
        return kept == began ? nil : began
    }

    /// A field of `kind`, named for it, at the end of the last section (one is made when there is none); its id.
    @discardableResult
    public mutating func add(_ kind: FieldKind) -> UUID {
        let name = Self.addable.first { $0.kind == kind }?.name ?? "Field"
        let section = entry.sections.last?.id ?? entry.addSection(entry.title.isEmpty ? "Details" : entry.title)
        return entry.add(EntryField(name: name, kind: kind), to: section)
    }

    /// Moves the fields at `offsets` of `section` to `destination`, as a list's move gives them.
    public mutating func move(in section: UUID, from offsets: IndexSet, to destination: Int) {
        guard let index = entry.sections.firstIndex(where: { $0.id == section }) else { return }
        let fields = entry.sections[index].fields
        let moved = offsets.filter(fields.indices.contains).map { fields[$0] }
        var rest = fields.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        // The destination counts the moved fields still in place before it.
        let before = offsets.count { $0 < destination }
        rest.insert(contentsOf: moved, at: min(max(destination - before, 0), rest.count))
        entry.sections[index].fields = rest
    }

    /// Sets the entry up from a code read (a QR code): its first One-Time Code field (one is made when there is none)
    /// holds the code's link; a title or a username left empty takes the code's issuer or account.
    public mutating func setUp(_ code: OneTimeCodeURI) {
        let field =
            entry.sections.lazy.flatMap(\.fields).first { $0.kind == .oneTimeCode }?.id ?? add(.oneTimeCode)
        entry.set(field, code.uri)
        if entry.title.trimmingCharacters(in: .whitespaces).isEmpty, let issuer = code.issuer { entry.title = issuer }
        if let user = entry.field(named: "Username"), user.value.isEmpty, !code.account.isEmpty {
            entry.set(user.id, code.account)
        }
    }

    /// A password made by `recipe`, with the system's generator, put into `field`.
    public mutating func generate(into field: UUID, recipe: PasswordRecipe) {
        var random = SystemRandomNumberGenerator()
        entry.set(field, recipe.generate(using: &random))
    }
}
