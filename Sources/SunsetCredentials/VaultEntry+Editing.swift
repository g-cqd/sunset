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

    /// Sets `field`'s value and, if the field is secret and its previous non-empty value differs, appends the previous
    /// value to `field.history` (capped at `EntryField.historyLimit`, roadmap 0092 D).
    public mutating func set(_ field: UUID, _ value: String, recordingHistoryAt now: Date) {
        change(field) { item in
            let previous = item.value
            item.value = value
            guard item.isSecret, !previous.isEmpty, previous != value else { return }
            var list = item.history ?? []
            if list.last?.value != previous {
                list.append(FieldHistoryItem(value: previous, changedAt: now))
                if list.count > EntryField.historyLimit { list.removeFirst(list.count - EntryField.historyLimit) }
                item.history = list
            }
        }
    }

    /// Sets `field`'s earlier values as they were elsewhere (an import keeps a password's history).
    mutating func setHistory(of field: UUID, _ history: [FieldHistoryItem]) {
        change(field) { $0.history = history.isEmpty ? nil : history }
    }

    /// Attaches `attachment` (if within `VaultAttachment.maxBytes`); returns false when oversized.
    @discardableResult
    public mutating func addAttachment(_ attachment: VaultAttachment) -> Bool {
        guard attachment.data.count <= VaultAttachment.maxBytes else { return false }
        var list = attachments ?? []
        list.removeAll { $0.id == attachment.id }
        list.append(attachment)
        attachments = list
        return true
    }

    public mutating func removeAttachment(_ id: UUID) {
        guard var list = attachments else { return }
        list.removeAll { $0.id == id }
        attachments = list.isEmpty ? nil : list
    }

    public mutating func constrain(_ field: UUID, _ constraints: [FieldConstraint]) {
        change(field) { $0.constraints = constraints }
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

    /// Moves `field` to where `target` is (dropped on it): dragged down within a section it lands after the target, dragged
    /// up or from another section, before it.
    public mutating func move(_ field: UUID, onto target: UUID) {
        guard field != target,
            let section = sections.firstIndex(where: { $0.fields.contains { $0.id == target } }),
            let to = sections[section].fields.firstIndex(where: { $0.id == target })
        else { return }
        // Taken out first: the target's place is then after it when the field came from above, before it otherwise.
        move(field, to: to, in: sections[section].id)
    }

    private mutating func change(_ field: UUID, _ body: (inout EntryField) -> Void) {
        for section in sections.indices {
            guard let index = sections[section].fields.firstIndex(where: { $0.id == field }) else { continue }
            body(&sections[section].fields[index])
            return
        }
    }
}
