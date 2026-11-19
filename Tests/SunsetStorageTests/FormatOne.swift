import CryptoKit
import Foundation
import SQLite3

@testable import SunsetStorage

/// A state database written as format 1 was (before task t48 C): kinds by name, times and counts in the clear.
enum FormatOne {
    struct Row {
        let kind: String
        let name: String
        let payload: String
        let sort: Double
        let count: Int
    }

    private static let transient = unsafe unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// Writes `rows` sealed as format 1 did, and one record of `damaged`'s kind and name whose bytes do not open.
    static func make(at path: String, key: StorageKey, rows: [Row], damaged: (kind: String, name: String)) throws {
        var handle: OpaquePointer?
        guard unsafe sqlite3_open(path, &handle) == SQLITE_OK else { throw CocoaError(.fileWriteUnknown) }
        defer { unsafe sqlite3_close(handle) }
        let schema = """
            CREATE TABLE records (kind TEXT NOT NULL, key BLOB NOT NULL, sealed BLOB NOT NULL, sort REAL NOT NULL DEFAULT 0,
                count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (kind, key)) WITHOUT ROWID;
            CREATE INDEX records_sort ON records (kind, sort);
            CREATE TABLE meta (name TEXT PRIMARY KEY, value BLOB NOT NULL) WITHOUT ROWID;
            PRAGMA user_version = 1;
            """
        guard unsafe sqlite3_exec(handle, schema, nil, nil, nil) == SQLITE_OK else {
            throw CocoaError(.fileWriteUnknown)
        }
        let seal = Seal(key: key, purpose: .state)
        let indexKey = key.derived("state-index")
        for row in rows {
            let index = Self.index(row.kind, row.name, indexKey)
            let sealed = try seal.seal(Data(row.payload.utf8), binding: seal.binding(row.kind) + [0] + index)
            unsafe insert(handle, row.kind, index, sealed, row.sort, row.count)
        }
        unsafe insert(
            handle,
            damaged.kind,
            index(damaged.kind, damaged.name, indexKey),
            Data(repeating: 0, count: 40),
            50,
            1
        )
        var statement: OpaquePointer?
        unsafe sqlite3_prepare_v2(handle, "INSERT INTO meta VALUES ('key', ?1)", -1, &statement, nil)
        unsafe bind(statement, 1, key.identifier)
        unsafe sqlite3_step(statement)
        unsafe sqlite3_finalize(statement)
    }

    private static func index(_ kind: String, _ name: String, _ key: SymmetricKey) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: Data("\(kind)\u{0}\(name)".utf8), using: key).prefix(16))
    }

    private static func insert(
        _ handle: OpaquePointer?,
        _ kind: String,
        _ index: Data,
        _ sealed: Data,
        _ sort: Double,
        _ count: Int
    ) {
        var statement: OpaquePointer?
        unsafe sqlite3_prepare_v2(handle, "INSERT INTO records VALUES (?1, ?2, ?3, ?4, ?5)", -1, &statement, nil)
        unsafe sqlite3_bind_text(statement, 1, kind, -1, transient)
        unsafe bind(statement, 2, index)
        unsafe bind(statement, 3, sealed)
        unsafe sqlite3_bind_double(statement, 4, sort)
        unsafe sqlite3_bind_int64(statement, 5, Int64(count))
        unsafe sqlite3_step(statement)
        unsafe sqlite3_finalize(statement)
    }

    private static func bind(_ statement: OpaquePointer?, _ column: Int32, _ data: Data) {
        _ = unsafe data.withUnsafeBytes {
            unsafe sqlite3_bind_blob(statement, column, $0.baseAddress, Int32($0.count), transient)
        }
    }
}
