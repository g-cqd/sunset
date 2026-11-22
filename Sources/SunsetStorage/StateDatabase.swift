import CryptoKit
public import Foundation
import SQLite3
public import SunsetRuntime

/// The database of Sunset's small records (R12, roadmap 0030 step ST-3): page history, site zoom, site permissions and
/// downloads, in one SQLite file with a version. Every record is sealed (`SealedTable`); the file holds no address or title in
/// the clear, not even in what names a record. A file that does not read is set aside and said, and a new one is made; one
/// sealed with another key is left as it is.
@MainActor
public final class StateDatabase {
    /// 2: kinds, times and counts sealed (task t48 C); 1 is resealed at its first opening.
    public static let currentVersion = 2
    static let what = "Sunset's database of history and site settings"

    public struct Opened {
        /// Nil when there is none to use: locked, or it could not be made.
        public let database: StateDatabase?
        public let problem: StorageProblem?
    }

    private enum Attempt {
        case opened(StateDatabase)
        case locked, unreadable
    }

    var handle: OpaquePointer?
    let seal: Seal
    let indexKey: SymmetricKey
    public private(set) var version = 0

    private init(handle: OpaquePointer?, key: StorageKey) {
        self.handle = handle
        seal = Seal(key: key, purpose: .state)
        indexKey = key.derived("state-index")
    }

    isolated deinit { close() }

    /// Closes the database, its write-ahead log emptied first: nothing of what was written or deleted stays in the log beside
    /// it (roadmap 0051 B). Closed once; a database closed is not used again.
    public func close() {
        guard handle != nil else { return }
        compact()
        unsafe sqlite3_close(handle)
        handle = nil
    }

    /// Writes the log into the database and empties it (after a removal of many records: history cleared).
    public func compact() {
        run("PRAGMA wal_checkpoint(TRUNCATE)")
    }

    /// Opens the database at `path`, making it when there is none (":memory:" for one that is never written).
    public static func open(at path: String, key: StorageKey, now: Date = Runtime.live.now()) -> Opened {
        switch attempt(path, key) {
            case .opened(let database): return Opened(database: database, problem: nil)
            case .locked:
                return Opened(
                    database: nil,
                    problem: StorageProblem(what: what, path: path, movedTo: nil, kind: .locked)
                )
            case .unreadable:
                let aside = path == ":memory:" ? nil : StoredFile.moveAside(path, now: now)
                if let aside {
                    // Its write-ahead log and index go with it: they belong to that file.
                    for suffix in ["-wal", "-shm"] {
                        try? FileManager.default.moveItem(atPath: path + suffix, toPath: aside + suffix)
                    }
                }
                let problem = StorageProblem(what: what, path: path, movedTo: aside)
                guard aside != nil, case .opened(let database) = attempt(path, key) else {
                    return Opened(database: nil, problem: problem)
                }
                return Opened(database: database, problem: problem)
        }
    }

    private static func attempt(_ path: String, _ key: StorageKey) -> Attempt {
        // Its owner's only (roadmap 0051 A): made so, and set so when it was made before.
        if path != ":memory:" { SQLiteBinding.ownFolder(of: path) }
        var handle: OpaquePointer?
        guard unsafe sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else {
            unsafe sqlite3_close(handle)
            return .unreadable
        }
        let database = unsafe StateDatabase(handle: handle, key: key)
        // The file, and its log and index (SQLite gives them the database's mode), its owner's only.
        if path != ":memory:" {
            for file in [path, path + "-wal", path + "-shm"] where FileManager.default.fileExists(atPath: file) {
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file)
            }
        }
        // A record deleted is overwritten, not left in a free page (roadmap 0051 B).
        guard database.run("PRAGMA secure_delete = ON") else { return .unreadable }
        // Ordered writes without a wait for the disk at each record: a crash keeps the database whole; the last records
        // before a power loss may be gone, which history can bear.
        guard database.run("PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;"),
            let found = database.number("PRAGMA user_version"), database.text("PRAGMA quick_check") == "ok"
        else { return .unreadable }
        return database.settle(version: found, key: key)
    }

    /// A database just opened, by its version: made when new, refused when a later Sunset's or another key's, brought to
    /// this version when an earlier one's.
    private func settle(version found: Int, key: StorageKey) -> Attempt {
        if found == 0 {
            guard create(keyIdentifier: key.identifier) else { return .unreadable }
        } else if found > Self.currentVersion {
            // A later Sunset's: not read as this version's.
            return .unreadable
        } else if let kept = blob("SELECT value FROM meta WHERE name = 'key'"), kept != key.identifier {
            return .locked
        } else if found == 1 {
            guard migrateFromOne() else { return .unreadable }
        }
        version = Self.currentVersion
        return .opened(self)
    }

    private func create(keyIdentifier: Data) -> Bool {
        run(
            """
            BEGIN;
            CREATE TABLE records (kind TEXT NOT NULL, key BLOB NOT NULL, sealed BLOB NOT NULL, sort REAL NOT NULL DEFAULT 0,
                count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (kind, key)) WITHOUT ROWID;
            CREATE INDEX records_sort ON records (kind, sort);
            CREATE TABLE meta (name TEXT PRIMARY KEY, value BLOB NOT NULL) WITHOUT ROWID;
            PRAGMA user_version = \(Self.currentVersion);
            COMMIT;
            """
        ) && execute("INSERT INTO meta (name, value) VALUES ('key', ?1)", [.blob(keyIdentifier)])
    }

    /// The records of one kind ("history", "zoom").
    public func table(_ kind: String) -> SealedTable {
        SealedTable(database: self, kind: kind)
    }

    /// Runs `body` as one transaction: many records written at the cost of one.
    public func transaction(_ body: () -> Void) {
        guard run("BEGIN") else { return body() }
        body()
        run("COMMIT")
    }

    /// A note of the database's own (which files were imported), not sealed: never anything of the person's.
    public func note(_ name: String) -> Data? {
        blob("SELECT value FROM meta WHERE name = ?1", [.text("note." + name)])
    }

    public func setNote(_ name: String, _ value: Data) {
        execute(
            "INSERT INTO meta (name, value) VALUES (?1, ?2) ON CONFLICT(name) DO UPDATE SET value = ?2",
            [.text("note." + name), .blob(value)]
        )
    }

    func setVersionForTesting(_ version: Int) {
        run("PRAGMA user_version = \(version)")
    }

    func corruptForTesting(kind: String) {
        execute("UPDATE records SET sealed = zeroblob(40) WHERE kind = ?1", [.text(tag(kind))])
    }
}
