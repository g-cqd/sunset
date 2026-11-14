import CryptoKit
public import Foundation
import SQLite3

/// The records of one kind in the state database (R12, step ST-3), each sealed on its own. A record is named by what its
/// owner calls it (an address, a host); the file holds only a keyed hash of that name, so that a record can be found and
/// replaced without the name being written. Beside each record are two plain numbers its owner chooses (`sort`: a time, an
/// order; `count`), for removing by time without opening anything. Searching is its owner's, in memory.
@MainActor
public struct SealedTable {
    public struct Row: Sendable {
        public let payload: Data
        public let sort: Double
        public let count: Int
    }

    let database: StateDatabase
    let kind: String

    /// Runs `body` as one transaction of the database: many records written at the cost of one.
    public func transaction(_ body: () -> Void) { database.transaction(body) }

    /// What names the record in the file: a keyed hash of its kind and name, cut to 16 bytes.
    private func index(_ name: String) -> Data {
        Data(
            HMAC<SHA256>.authenticationCode(for: Data("\(kind)\u{0}\(name)".utf8), using: database.indexKey).prefix(16)
        )
    }

    /// What is bound into a record's seal: its kind and what names it in the file, so that a record cannot stand for another.
    private var binding: Data { database.seal.binding(kind) + [0] }

    /// Keeps `payload` under `name`, in place of what was there.
    public func put(_ name: String, payload: Data, sort: Double = 0, count: Int = 0) {
        let index = index(name)
        guard let sealed = try? database.seal.seal(payload, binding: binding + index) else { return }
        database.execute(
            "INSERT INTO records (kind, key, sealed, sort, count) VALUES (?1, ?2, ?3, ?4, ?5) "
                + "ON CONFLICT(kind, key) DO UPDATE SET sealed = ?3, sort = ?4, count = ?5",
            [.text(kind), .blob(index), .blob(sealed), .real(sort), .integer(count)]
        )
    }

    /// Every record, opened, the highest `sort` first; and how many did not open (altered or damaged: not given). For a
    /// table of few records; a large one is opened off the main actor (`sealed()`).
    public func all() -> (rows: [Row], unreadable: Int) {
        let read = sealed().open { $0 }
        return (read.values, read.unreadable)
    }

    /// The table's records as the file holds them, still sealed, to be opened where its owner chooses.
    /// - Complexity: O(the records' bytes): one pass over the table, in the order the file holds it (no sort by the database,
    ///   which would look each record up again).
    public func sealed() -> SealedRows {
        var records: [SealedRows.Record] = []
        database.rows("SELECT key, sealed, sort, count FROM records WHERE kind = ?1", [.text(kind)]) { statement in
            records.append(
                SealedRows.Record(
                    index: unsafe StateDatabase.data(statement, 0),
                    bytes: unsafe StateDatabase.data(statement, 1),
                    sort: unsafe sqlite3_column_double(statement, 2),
                    count: Int(unsafe sqlite3_column_int64(statement, 3))
                )
            )
        }
        return SealedRows(records: records, seal: database.seal, binding: binding)
    }

    public func count() -> Int { database.number("SELECT COUNT(*) FROM records WHERE kind = ?1", [.text(kind)]) ?? 0 }

    public func remove(_ name: String) {
        database.execute("DELETE FROM records WHERE kind = ?1 AND key = ?2", [.text(kind), .blob(index(name))])
    }

    public func remove(sortBelow limit: Double) {
        database.execute("DELETE FROM records WHERE kind = ?1 AND sort < ?2", [.text(kind), .real(limit)])
    }

    public func remove(sortAtLeast limit: Double) {
        database.execute("DELETE FROM records WHERE kind = ?1 AND sort >= ?2", [.text(kind), .real(limit)])
    }

    public func removeAll() { database.execute("DELETE FROM records WHERE kind = ?1", [.text(kind)]) }
}
