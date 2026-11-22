public import Foundation

/// The entries and the person's templates of a vault (roadmap 0092 A): each one sealed record under its id. Refused while
/// the vault is locked.
extension Vault {
    public func save(_ entry: VaultEntry) throws {
        try put(JSONEncoder().encode(VaultRecord.entry(entry)), as: entry.id)
    }

    public func save(_ template: EntryTemplate) throws {
        try put(JSONEncoder().encode(VaultRecord.template(template)), as: template.id)
    }

    public func remove(entry id: UUID) throws {
        guard !lock.isLocked else { throw Refused() }
        try file.remove(id)
    }

    /// The sites never to offer saving for, sealed as a record of their own.
    public func neverSave() throws -> Set<String> {
        let lists: [[String]] = try records().map { if case .neverSave(let sites) = $0 { sites } else { [] } }
        return Set(lists.joined())
    }

    public func setNeverSave(_ sites: Set<String>) throws {
        try put(JSONEncoder().encode(VaultRecord.neverSave(sites.sorted())), as: Self.neverSaveRecord)
    }

    /// The fixed id of the never-save record.
    static let neverSaveRecord = UUID(uuid: (0x5E, 0x7C, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, 0x01))

    /// Every entry, in no order that means anything.
    public func entries() throws -> [VaultEntry] {
        try records().compactMap { if case .entry(let entry) = $0 { entry } else { nil } }
    }

    /// The person's own templates (the shipped ones are `EntryTemplate.shipped`).
    public func templates() throws -> [EntryTemplate] {
        try records().compactMap { if case .template(let template) = $0 { template } else { nil } }
    }

    private func records() throws -> [VaultRecord] {
        guard !lock.isLocked else { throw Refused() }
        return try file.recordIDs.compactMap { id in
            try record(id).map { try JSONDecoder().decode(VaultRecord.self, from: $0) }
        }
    }
}
