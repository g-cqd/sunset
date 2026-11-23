public import Foundation

/// Changing an entry's fields: what an entry made from a template may do freely (ADR-0092).
extension VaultEntry {
    /// A new, empty section at the end; its id.
    @discardableResult
    public mutating func addSection(_ name: String) -> UUID {
        let section = EntrySection(name: name)
        sections.append(section)
        return section.id
    }

    /// `field` at the end of `section`; its id.
    @discardableResult
    public mutating func add(_ field: EntryField, to section: UUID) -> UUID {
        guard let index = sections.firstIndex(where: { $0.id == section }) else { return field.id }
        sections[index].fields.append(field)
        return field.id
    }

    public mutating func rename(_ field: UUID, to name: String) {
        change(field) { $0.name = name }
    }

    public mutating func set(_ field: UUID, _ value: String) {
        change(field) { $0.value = value }
    }

    public mutating func constrain(_ field: UUID, _ constraints: [FieldConstraint]) {
        change(field) { $0.constraints = constraints }
    }

    /// Gives the field another kind, its value kept as written (n104).
    public mutating func setKind(_ field: UUID, _ kind: FieldKind) {
        change(field) { $0.kind = kind }
    }

    /// Marks the field secret, or not (n102).
    public mutating func markSecret(_ field: UUID, _ secret: Bool) {
        change(field) { $0.markedSecret = secret }
    }

    public mutating func remove(_ field: UUID) {
        for index in sections.indices { sections[index].fields.removeAll { $0.id == field } }
    }

    /// Moves `field` to `position` in `section` (from wherever it was).
    public mutating func move(_ field: UUID, to position: Int, in section: UUID) {
        guard let moved = sections.lazy.flatMap(\.fields).first(where: { $0.id == field }),
            let target = sections.firstIndex(where: { $0.id == section })
        else { return }
        remove(field)
        let fields = sections[target].fields
        sections[target].fields.insert(moved, at: min(max(position, 0), fields.count))
    }

    private mutating func change(_ field: UUID, _ body: (inout EntryField) -> Void) {
        for section in sections.indices {
            guard let index = sections[section].fields.firstIndex(where: { $0.id == field }) else { continue }
            body(&sections[section].fields[index])
            return
        }
    }
}
