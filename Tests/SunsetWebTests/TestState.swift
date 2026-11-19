import Foundation
import SQLite3
import SunsetStorage
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// A state database for a test: at a path (kept between opens), or in memory.
@MainActor
enum TestState {
    struct Unavailable: Error {}

    static let key = try? StorageKeyring(vault: MemoryKeyVault()).key()

    static func table(_ kind: String, at path: String = ":memory:") throws -> SealedTable {
        guard let key, let database = StateDatabase.open(at: path, key: key).database else { throw Unavailable() }
        return database.table(kind)
    }

    /// The history file as Sunset wrote it before the state database.
    static func makeLegacyHistory(at path: String, pages: [HistoryEntry]) throws {
        var handle: OpaquePointer?
        guard unsafe sqlite3_open(path, &handle) == SQLITE_OK else { throw Unavailable() }
        defer { unsafe sqlite3_close(handle) }
        var sql =
            "CREATE TABLE pages (url TEXT PRIMARY KEY, title TEXT NOT NULL, visits INTEGER NOT NULL, last REAL NOT NULL);"
        for page in pages {
            let last = page.lastVisit.timeIntervalSince1970
            sql += "INSERT INTO pages VALUES ('\(page.url)', '\(page.title)', \(page.visits), \(last));"
        }
        guard unsafe sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw Unavailable() }
    }
}
