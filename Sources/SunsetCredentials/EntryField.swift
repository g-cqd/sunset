public import Foundation

/// One field of an entry (ADR-0092): a name, a kind, a value written as text, and what the value should be.
public struct EntryField: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var kind: FieldKind
    public var value: String
    public var constraints: [FieldConstraint]
    /// Marked secret, or not, by the person, whatever its kind (n102); nil: as its kind says. Optional so that a record
    /// written before it reads.
    public var markedSecret: Bool?

    /// Hidden until shown, monospaced, never searched, copied as a secret: its kind's, or as the person marked it.
    public var isSecret: Bool {
        markedSecret ?? kind.isConcealed
    }

    public init(
        id: UUID = UUID(),
        name: String,
        kind: FieldKind,
        value: String = "",
        constraints: [FieldConstraint] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.value = value
        self.constraints = constraints
    }

    /// Its constraints, and those its kind carries (a choice is among its options).
    var allConstraints: [FieldConstraint] {
        constraints + (kind.options.map { [.oneOf($0)] } ?? [])
    }
}
