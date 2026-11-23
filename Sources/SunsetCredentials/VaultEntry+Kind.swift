public import Foundation

/// A field given another kind its value may not fit (t334): the value kept as written, or kept in a new field beside it so
/// that nothing is lost.
extension VaultEntry {
    /// Gives `field` the kind `kind`. When `keepingOld`, a value that does not fit is moved to a new note right after it
    /// ("Name (before)", secret if the field was), and the field starts empty; its id is returned. Otherwise the value
    /// stays as written. Nil when no field was added.
    @discardableResult
    public mutating func changeKind(_ field: UUID, to kind: FieldKind, keepingOld: Bool) -> UUID? {
        guard let (section, index) = place(of: field) else { return nil }
        let old = sections[section].fields[index]
        sections[section].fields[index].kind = kind
        guard keepingOld, kind.fit(old.value) != .fits else { return nil }
        var kept = EntryField(name: "\(old.name) (before)", kind: .multiline, value: old.value)
        kept.markedSecret = old.isSecret ? true : nil
        sections[section].fields[index].value = ""
        sections[section].fields.insert(kept, at: index + 1)
        return kept.id
    }

    /// A field's name, kind and secrecy as its editing sheet left them: only what changed is written (a sheet saved
    /// unchanged changes nothing), and a secrecy that is its kind's own is not marked.
    public mutating func apply(name: String, kind: FieldKind, secret: Bool, keepingOld: Bool, to field: UUID) {
        guard let (section, index) = place(of: field) else { return }
        let before = sections[section].fields[index]
        if kind != before.kind { changeKind(field, to: kind, keepingOld: keepingOld) }
        if name != before.name { rename(field, to: name) }
        guard let (now, at) = place(of: field) else { return }
        let marked: Bool? = secret == kind.isConcealed ? nil : secret
        if sections[now].fields[at].markedSecret != marked, secret != before.isSecret || kind != before.kind {
            sections[now].fields[at].markedSecret = marked
        }
    }

    private func place(of field: UUID) -> (section: Int, index: Int)? {
        for section in sections.indices {
            if let index = sections[section].fields.firstIndex(where: { $0.id == field }) { return (section, index) }
        }
        return nil
    }
}
