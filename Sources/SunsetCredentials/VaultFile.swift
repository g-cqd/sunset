public import Foundation
public import SunsetStorage

/// A vault on disk (ADR-0090, roadmap 0091 A): one SQLite file of its own, 0600 in a 0700 folder, `secure_delete` on. In the
/// clear only its id, its format version and, per record, an opaque id: every record is sealed with the vault's key for its
/// purpose, bound to the vault and the record, so a record cannot be moved to another vault or slot unseen.
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
    private func identity(_ recordID: UUID) -> String {
        "vault:\(id.uuidString)/record:\(recordID.uuidString)"
    }

    /// Writes `record` sealed under `recordID`, replacing what was there.
    public func put(_ record: Data, as recordID: UUID, key: StorageKey) throws(Failure) {
        guard let sealed = try? Seal(key: key, purpose: .vaultRecord).seal(record, identity: identity(recordID)),
            sql.run("INSERT OR REPLACE INTO records VALUES (?, ?)", [.text(recordID.uuidString), .blob(sealed)])
        else { throw .cannotOpen }
    }

    /// The record `recordID`, opened; nil when there is none. Throws `damaged` when it does not open with `key` here.
    public func record(_ recordID: UUID, key: StorageKey) throws(Failure) -> Data? {
        guard let sealed = sql.column("SELECT sealed FROM records WHERE id = ?", [.text(recordID.uuidString)]).first
        else { return nil }
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
}
