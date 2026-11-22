public import Foundation

/// An entry of a vault (roadmap 0092, ADR-0092): sections of typed fields, made from a template and free to differ from it;
/// a Markdown note; tags and a folder. Kept as one sealed record.
public struct VaultEntry: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var title: String
    /// The template it was made from, if any.
    public var template: UUID?
    public var sections: [EntrySection]
    public var note: String
    public var tags: [String]
    public var folder: String?
    public var isFavorite: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        template: UUID? = nil,
        sections: [EntrySection] = [],
        note: String = "",
        tags: [String] = [],
        folder: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.template = template
        self.sections = sections
        self.note = note
        self.tags = tags
        self.folder = folder
        self.isFavorite = isFavorite
    }

    /// The first field of that name, in section order.
    public func field(named name: String) -> EntryField? {
        sections.lazy.flatMap(\.fields).first { $0.name == name }
    }

    /// Each field whose value breaks a constraint, with the constraint, at `now`.
    public func problems(now: Date) -> [FieldProblem] {
        sections.flatMap(\.fields)
            .flatMap { field in
                field.allConstraints.filter { !$0.holds(for: field.value, now: now) }
                    .map { FieldProblem(field: field.id, constraint: $0) }
            }
    }

    /// Whether a problem keeps it from being saved (a required field left empty).
    public func blocksSave(now: Date) -> Bool {
        problems(now: now).contains { $0.constraint.blocksSave }
    }
}
