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

    /// What is kept is now what was edited.
    public mutating func saved() {
        kept = entry
    }

    public mutating func revert() {
        entry = kept
    }

    /// A field of `kind`, named for it, at the end of the last section (one is made when there is none); its id.
    @discardableResult
    public mutating func add(_ kind: FieldKind) -> UUID {
        let name = Self.addable.first { $0.kind == kind }?.name ?? "Field"
        let section = entry.sections.last?.id ?? entry.addSection(entry.title.isEmpty ? "Details" : entry.title)
        return entry.add(EntryField(name: name, kind: kind), to: section)
    }

    /// A password made by `recipe`, with the system's generator, put into `field`.
    public mutating func generate(into field: UUID, recipe: PasswordRecipe) {
        var random = SystemRandomNumberGenerator()
        entry.set(field, recipe.generate(using: &random))
    }
}
