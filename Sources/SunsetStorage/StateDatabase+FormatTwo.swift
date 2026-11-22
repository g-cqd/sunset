import CryptoKit
import Foundation
import SQLite3

/// Storage format 2 (design 0007, threat A4: a copy of the files): no kind's name, no time and no count in the clear. A
/// kind is a keyed tag; a record's time and count are sealed with its payload (`envelope`). Format 1 is resealed in one
/// transaction at the first opening (`migrateFromOne`).
extension StateDatabase {
    /// What stands for `kind` in the file: a keyed hash of its name, cut to 8 bytes, as hex.
    func tag(_ kind: String) -> String {
        HMAC<SHA256>.authenticationCode(for: Data("kind\u{0}\(kind)".utf8), using: indexKey)
            .prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// A record's time and count before its payload, sealed together: each 8 bytes, big-endian.
    nonisolated static func envelope(sort: Double, count: Int, payload: Data) -> Data {
        var bytes = Data(capacity: 16 + payload.count)
        withUnsafeBytes(of: sort.bitPattern.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: Int64(count).bigEndian) { bytes.append(contentsOf: $0) }
        bytes.append(payload)
        return bytes
    }

    /// The time, the count and the payload of an opened envelope; nil for one too short.
    nonisolated static func unwrap(_ envelope: Data) -> (sort: Double, count: Int, payload: Data)? {
        guard envelope.count >= 16 else { return nil }
        let start = envelope.startIndex
        let sort = envelope[start ..< start + 8].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        let count = envelope[start + 8 ..< start + 16].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        return (Double(bitPattern: sort), Int(Int64(bitPattern: count)), Data(envelope[(start + 16)...]))
    }

    /// Every record of format 1 resealed as format 2, in one transaction: each opened with its kind's name, sealed again with
    /// its time and count, filed under its kind's tag. One that does not open keeps its bytes (what cannot be read is never
    /// overwritten), filed under its tag. False, and nothing changed, when the transaction fails.
    func migrateFromOne() -> Bool {
        var rows: [FormatOneRow] = []
        self.rows("SELECT kind, key, sealed, sort, count FROM records") { statement in
            rows.append(
                FormatOneRow(
                    kind: unsafe String(cString: sqlite3_column_text(statement, 0)),
                    key: unsafe Self.data(statement, 1),
                    sealed: unsafe Self.data(statement, 2),
                    sort: unsafe sqlite3_column_double(statement, 3),
                    count: Int(unsafe sqlite3_column_int64(statement, 4))
                )
            )
        }
        guard run("BEGIN IMMEDIATE") else { return false }
        for row in rows {
            let binding = seal.binding(row.kind) + [0] + row.key
            var sealed = row.sealed
            if let payload = try? seal.open(row.sealed, binding: binding),
                let again = try? seal.seal(
                    Self.envelope(sort: row.sort, count: row.count, payload: payload),
                    binding: binding
                )
            {
                sealed = again
            }
            guard
                execute(
                    "UPDATE records SET kind = ?1, sealed = ?2, sort = 0, count = 0 WHERE kind = ?3 AND key = ?4",
                    [.text(tag(row.kind)), .blob(sealed), .text(row.kind), .blob(row.key)]
                )
            else {
                run("ROLLBACK")
                return false
            }
        }
        guard run("PRAGMA user_version = 2"), run("COMMIT") else {
            run("ROLLBACK")
            return false
        }
        compact()
        return true
    }
}
