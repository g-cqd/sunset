public import Foundation

/// One field of an entry (ADR-0092): a name, a kind, a value written as text, and what the value should be.
public struct EntryField: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var kind: FieldKind
    public var value: String
    public var constraints: [FieldConstraint]

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
