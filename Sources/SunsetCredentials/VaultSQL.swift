import Foundation
import SQLite3
import SunsetStorage

/// One SQLite connection of a vault's file: statements bound by value, blobs and text only.
final class VaultSQL {
    typealias Value = SQLiteBinding.Value

    private let handle: OpaquePointer?

    /// Opens or makes the file (0600; `secure_delete`, so a removed record is overwritten), or nil.
    init?(path: String, create: Bool) {
        var opened: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | (create ? SQLITE_OPEN_CREATE : 0)
        guard unsafe sqlite3_open_v2(path, &opened, flags, nil) == SQLITE_OK else {
            unsafe sqlite3_close(opened)
            return nil
        }
        handle = unsafe opened
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path)
        guard run("PRAGMA secure_delete = ON"), run("PRAGMA journal_mode = DELETE") else { return nil }
    }

    deinit {
        unsafe sqlite3_close(handle)
    }

    @discardableResult
    func run(_ sql: String, _ values: [Value] = []) -> Bool {
        guard let statement = prepare(sql, values) else { return false }
        defer { unsafe sqlite3_finalize(statement) }
        // A pragma answers with a row (its value); a write is done.
        let step = unsafe sqlite3_step(statement)
        return step == SQLITE_DONE || step == SQLITE_ROW
    }

    /// The first column of each row.
    func column(_ sql: String, _ values: [Value] = []) -> [Data] {
        guard let statement = prepare(sql, values) else { return [] }
        defer { unsafe sqlite3_finalize(statement) }
        var rows: [Data] = []
        while unsafe sqlite3_step(statement) == SQLITE_ROW {
            let count = Int(unsafe sqlite3_column_bytes(statement, 0))
            if let bytes = unsafe sqlite3_column_blob(statement, 0) {
                rows.append(unsafe Data(bytes: bytes, count: count))
            } else {
                rows.append(Data())
            }
        }
        return rows
    }

    private func prepare(_ sql: String, _ values: [Value]) -> OpaquePointer? {
        SQLiteBinding.prepare(sql, values, on: handle)
    }
}
