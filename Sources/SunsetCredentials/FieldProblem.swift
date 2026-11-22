public import Foundation

/// A field whose value breaks one of its constraints.
public struct FieldProblem: Hashable, Sendable {
    public let field: UUID
    public let constraint: FieldConstraint
}
