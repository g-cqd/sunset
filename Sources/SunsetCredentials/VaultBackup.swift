public import Foundation
public import SunsetRuntime
import SunsetStorage

/// Reads and writes Sunset's sealed vault backup format (`.svault`, roadmap 0095 A, ADR-0095).
///
/// Format v1 (all integers big-endian):
/// - `magic` (6 bytes): ASCII `SVAULT`
/// - `version` (1 byte): `1`
/// - `headerLength` (4 bytes): UTF-8 JSON header byte count (bounded by `maxHeaderBytes`)
/// - `header` (`headerLength` bytes): JSON with `vaultID`, `createdAt`, `factors` (only portable factors — never
///   `.touchID`, which is bound to one Mac's Secure Enclave), and `recordCount`
/// - `records` (`recordCount` items): each `id` (16-byte UUID) + `sealedLength` (4 bytes, bounded by `maxRecordBytes`)
///   + `sealed` bytes (already `Seal(.vaultRecord)`-sealed for `vaultID` and `id`)
///
/// Every record stays sealed under the vault's own key: exporting works even while the vault is locked, and nothing
/// plaintext ever touches the backup bytes.
public enum VaultBackup {
    public static let fileExtension = "svault"
    public static let magic = Data("SVAULT".utf8)
    public static let currentVersion: UInt8 = 1
    public static let maxHeaderBytes = 1 << 20
    public static let maxRecordCount = 500_000
    public static let maxRecordBytes = 64 << 20

    public enum Failure: Error, Equatable, Sendable {
        case notABackup
        case unsupportedVersion(UInt8)
        case damaged
        case noPortableFactors
        case wrongSecret
        case writeFailed
    }

    public struct Header: Equatable, Sendable {
        public let version: UInt8
        public let vaultID: UUID
        public let createdAt: Date
        public let factors: [Vault.Factor]
        public let recordCount: Int
    }

    public struct Contents: Equatable, Sendable {
        public let header: Header
        public let entries: [VaultEntry]
        public let templates: [EntryTemplate]
        public let neverSave: Set<String>
    }

    public struct RestoreSummary: Equatable, Sendable {
        public let entriesAdded: Int
        public let entriesUpdated: Int
        public let entriesUnchanged: Int
        public let templatesAdded: Int
        public let neverSaveAdded: Int
    }

    struct RawHeader: Codable, Equatable {
        let vaultID: UUID
        let createdAt: Date
        let factorSlots: [VaultFile.FactorSlot]
        let recordCount: Int
    }

    struct Parsed {
        let version: UInt8
        let rawHeader: RawHeader
        let records: [(id: UUID, sealed: Data)]
    }

    /// True when `data` begins with the `SVAULT` magic prefix.
    public static func isBackup(_ data: Data) -> Bool {
        data.prefix(magic.count) == magic
    }

    /// Exports `vault` to a sealed `.svault` byte buffer. Works whether `vault` is locked or unlocked.
    @MainActor
    public static func export(from vault: Vault, createdAt: Date = Runtime.live.now()) throws(Failure) -> Data {
        try export(from: vault.file, createdAt: createdAt)
    }

    /// Exports `file` directly without unlocking: copies its portable factor slots (excluding `.touchID`) and its
    /// already-sealed records verbatim.
    public static func export(from file: VaultFile, createdAt: Date = Runtime.live.now()) throws(Failure) -> Data {
        guard let allSlots = try? file.factorSlots() else { throw .damaged }
        let portable = allSlots.filter { $0.factor != .touchID }
        guard !portable.isEmpty else { throw .noPortableFactors }
        let rawRecords = file.rawRecords()
        let rawHeader = RawHeader(
            vaultID: file.id,
            createdAt: createdAt,
            factorSlots: portable,
            recordCount: rawRecords.count
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let headerBytes = try? encoder.encode(rawHeader), headerBytes.count <= maxHeaderBytes else {
            throw .writeFailed
        }

        var out = Data()
        out.append(magic)
        out.append(currentVersion)
        appendUInt32(UInt32(headerBytes.count), to: &out)
        out.append(headerBytes)
        for (id, sealed) in rawRecords {
            guard sealed.count <= maxRecordBytes else { throw .writeFailed }
            appendUUID(id, to: &out)
            appendUInt32(UInt32(sealed.count), to: &out)
            out.append(sealed)
        }
        return out
    }

    /// Writes a sealed `.svault` backup atomically with mode `0600` (owner-only).
    @MainActor
    public static func write(from vault: Vault, to url: URL, createdAt: Date = Runtime.live.now()) throws(Failure)
        -> Data
    {
        let data = try export(from: vault, createdAt: createdAt)
        try writeOwnerOnly(data, to: url)
        return data
    }

    /// Writes `data` to `url` with `0600` permissions via atomic temp-file swap.
    public static func writeOwnerOnly(_ data: Data, to url: URL) throws(Failure) {
        let dir = url.deletingLastPathComponent()
        let temp = dir.appending(path: ".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
        let made = FileManager.default.createFile(
            atPath: temp.path,
            contents: data,
            attributes: [.posixPermissions: 0o600]
        )
        guard made else { throw .writeFailed }
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temp.path)
        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw .writeFailed
        }
    }

    /// Reads the unencrypted envelope metadata (version, vault id, date, portable factors, record count) without needing
    /// any unlock secret.
    public static func inspect(_ data: Data) throws(Failure) -> Header {
        let parsed = try parse(data)
        return Header(
            version: parsed.version,
            vaultID: parsed.rawHeader.vaultID,
            createdAt: parsed.rawHeader.createdAt,
            factors: parsed.rawHeader.factorSlots.map(\.factor),
            recordCount: parsed.rawHeader.recordCount
        )
    }

    /// Opens a `.svault` backup with its master password.
    public static func open(_ data: Data, password: String) throws(Failure) -> Contents {
        let parsed = try parse(data)
        guard let slot = parsed.rawHeader.factorSlots.first(where: { $0.factor == .password }),
            let salt = slot.salt,
            let cost = slot.cost,
            cost.isWithinBounds,
            let stretched = try? MasterPassword.stretch(password, salt: salt, cost: cost),
            let vaultKey = try? slot.wrapped.unwrap(with: stretched, vault: parsed.rawHeader.vaultID)
        else { throw .wrongSecret }
        return try decrypt(parsed, with: vaultKey)
    }

    /// Opens a `.svault` backup with its recovery code.
    public static func open(_ data: Data, recoveryCode: RecoveryCode) throws(Failure) -> Contents {
        let parsed = try parse(data)
        guard let slot = parsed.rawHeader.factorSlots.first(where: { $0.factor == .recoveryCode }),
            let vaultKey = try? slot.wrapped.unwrap(
                with: recoveryCode.factorKey(vault: parsed.rawHeader.vaultID),
                vault: parsed.rawHeader.vaultID
            )
        else { throw .wrongSecret }
        return try decrypt(parsed, with: vaultKey)
    }

    /// Merges opened backup contents into an unlocked `vault`: adds missing entries and templates, keeps existing
    /// entries with the same id untouched unless `overwriteExisting` is true, and unions `neverSave`.
    @MainActor
    public static func restore(
        _ contents: Contents,
        into vault: Vault,
        overwriteExisting: Bool = false
    ) throws -> RestoreSummary {
        let existing = try vault.contents()
        let byID = Dictionary(uniqueKeysWithValues: existing.entries.map { ($0.id, $0) })
        let existingTemplates = Set(existing.templates.map(\.id))

        var added = 0
        var updated = 0
        var unchanged = 0
        for entry in contents.entries {
            if let current = byID[entry.id] {
                if overwriteExisting, current != entry {
                    try vault.save(entry)
                    updated += 1
                } else {
                    unchanged += 1
                }
            } else {
                try vault.save(entry)
                added += 1
            }
        }

        var templatesAdded = 0
        for template in contents.templates where !existingTemplates.contains(template.id) {
            try vault.save(template)
            templatesAdded += 1
        }

        let mergedNever = existing.neverSave.union(contents.neverSave)
        let neverAdded = mergedNever.count - existing.neverSave.count
        if neverAdded > 0 { try vault.setNeverSave(mergedNever) }

        return RestoreSummary(
            entriesAdded: added,
            entriesUpdated: updated,
            entriesUnchanged: unchanged,
            templatesAdded: templatesAdded,
            neverSaveAdded: neverAdded
        )
    }
}
