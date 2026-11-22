public import Foundation

/// What an entry is made from (ADR-0092): its sections and fields, empty. Shipped ones, and the person's own. An entry
/// made from one may then differ from it freely; a template's change reaches its entries only when the person says so.
public struct EntryTemplate: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    /// An SF Symbol.
    public var symbol: String
    public var sections: [EntrySection]

    public init(id: UUID = UUID(), name: String, symbol: String, sections: [EntrySection]) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.sections = sections
    }

    /// A new entry: its fields and sections with ids of their own, its values empty.
    public func makeEntry(title: String) -> VaultEntry {
        let fresh = sections.map { section in
            EntrySection(
                name: section.name,
                fields: section.fields.map { EntryField(name: $0.name, kind: $0.kind, constraints: $0.constraints) }
            )
        }
        return VaultEntry(title: title, template: id, sections: fresh)
    }

    /// A shipped template: one section of `fields`, some with `constraints`, under a fixed id.
    static func shipped(
        _ id: String,
        _ name: String,
        _ symbol: String,
        _ fields: [(String, FieldKind)],
        _ constraints: [String: [FieldConstraint]] = [:]
    ) -> Self {
        let made = fields.map { EntryField(name: $0.0, kind: $0.1, constraints: constraints[$0.0] ?? []) }
        return EntryTemplate(
            id: UUID(uuidString: "5E7C0000-0000-4000-8000-0000000000\(id)") ?? UUID(),
            name: name,
            symbol: symbol,
            sections: made.isEmpty ? [] : [EntrySection(name: name, fields: made)]
        )
    }
}
