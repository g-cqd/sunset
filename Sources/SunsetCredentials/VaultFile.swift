public import Foundation
public import SunsetStorage

/// A vault on disk: one SQLite file of its own, 0600 in a 0700 folder, `secure_delete` on. In the clear only its id, its
/// format version and, per record, an opaque id: every record is sealed with the vault's key for its purpose, bound to the
/// vault and the record, so a record cannot be moved to another vault or slot unseen.
public final class VaultFile {
    public enum Failure: Error, Equatable {
        case cannotOpen
        case notAVault
        case damaged
    }

    public static let formatVersion = 1
    public let id: UUID
    let sql: VaultSQL

    private init(id: UUID, sql: VaultSQL) {
        self.id = id
        self.sql = sql
    }

    /// Makes a new vault at `path` (its folder 0700).
    public static func create(at path: String, id: UUID = UUID()) throws(Failure) -> VaultFile {
        SQLiteBinding.ownFolder(of: path)
        guard !FileManager.default.fileExists(atPath: path), let sql = VaultSQL(path: path, create: true),
            sql.run("CREATE TABLE vault (name TEXT PRIMARY KEY, value BLOB NOT NULL)"),
            sql.run("CREATE TABLE records (id TEXT PRIMARY KEY, sealed BLOB NOT NULL)"),
            sql.run("INSERT INTO vault VALUES ('id', ?)", [.blob(Data(id.uuidString.utf8))]),
            sql.run("INSERT INTO vault VALUES ('format', ?)", [.blob(Data("\(formatVersion)".utf8))])
        else { throw .cannotOpen }
        return VaultFile(id: id, sql: sql)
    }

    /// Opens the vault at `path`; a file that is not a vault, or a later format's, is refused.
    public static func open(at path: String) throws(Failure) -> VaultFile {
        guard FileManager.default.fileExists(atPath: path), let sql = VaultSQL(path: path, create: false) else {
            throw .cannotOpen
        }
        guard
            let idText = sql.column("SELECT value FROM vault WHERE name = 'id'").first
                .map({ String(decoding: $0, as: UTF8.self) }),
            let id = UUID(uuidString: idText),
            let format = sql.column("SELECT value FROM vault WHERE name = 'format'").first
                .flatMap({ Int(String(decoding: $0, as: UTF8.self)) }),
            format <= formatVersion
        else { throw .notAVault }
        return VaultFile(id: id, sql: sql)
    }

    /// What a record's seal is bound to: this vault and this slot.
    package func identity(_ recordID: UUID) -> String {
        "vault:\(id.uuidString)/record:\(recordID.uuidString)"
    }

    /// Writes `record` sealed under `recordID`, replacing what was there.
    public func put(_ record: Data, as recordID: UUID, key: StorageKey) throws(Failure) {
        guard let sealed = try? Seal(key: key, purpose: .vaultRecord).seal(record, identity: identity(recordID))
        else { throw .cannotOpen }
        try putSealed(sealed, as: recordID)
    }

    /// Writes already-sealed bytes under `recordID` (used when `SunsetVaultService.xpc` seals records out-of-process, N-S5).
    package func putSealed(_ sealed: Data, as recordID: UUID) throws(Failure) {
        guard sql.run("INSERT OR REPLACE INTO records VALUES (?, ?)", [.text(recordID.uuidString), .blob(sealed)])
        else { throw .cannotOpen }
    }

    /// Reads the raw sealed blob stored under `recordID` without opening it (for out-of-process XPC decryption, N-S5).
    package func sealedRecord(_ recordID: UUID) -> Data? {
        sql.column("SELECT sealed FROM records WHERE id = ?", [.text(recordID.uuidString)]).first
    }

    /// The record `recordID`, opened; nil when there is none. Throws `damaged` when it does not open with `key` here.
    public func record(_ recordID: UUID, key: StorageKey) throws(Failure) -> Data? {
        guard let sealed = sealedRecord(recordID) else { return nil }
        guard let plain = try? Seal(key: key, purpose: .vaultRecord).open(sealed, identity: identity(recordID)) else {
            throw .damaged
        }
        return plain
    }

    public func remove(_ recordID: UUID) throws(Failure) {
        guard sql.run("DELETE FROM records WHERE id = ?", [.text(recordID.uuidString)]) else { throw .cannotOpen }
    }

    /// The ids of its records, in no order that means anything.
    public var recordIDs: [UUID] {
        sql.column("SELECT id FROM records ORDER BY id")
            .compactMap { UUID(uuidString: String(decoding: $0, as: UTF8.self)) }
    }

    /// Every `(id, sealed)` pair as stored on disk, ordered by id, for sealing-preserving export (`.svault`).
    func rawRecords() -> [(id: UUID, sealed: Data)] {
        recordIDs.compactMap { id in
            guard let sealed = sql.column("SELECT sealed FROM records WHERE id = ?", [.text(id.uuidString)]).first
            else { return nil }
            return (id, sealed)
        }
    }
}
