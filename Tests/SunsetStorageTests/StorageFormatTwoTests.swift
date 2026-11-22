import CryptoKit
import Foundation
import SQLite3
import Testing

@testable import SunsetStorage

/// Design 0007, threat A4 (a copy of the files): format 2 keeps no kind's name, no time and no count in the clear; a
/// kind is a keyed tag, a record's time and count are sealed with it. A database of format 1 is resealed in one
/// transaction at its first opening; a record that does not open is left as it was.
@MainActor
@Suite("Storage format 2: nothing about a record in the clear")
struct StorageFormatTwoTests {
    private let key = StorageKey.random()

    private func path() -> String {
        NSTemporaryDirectory() + "format2-\(UUID().uuidString).sqlite"
    }

    private func columns(_ path: String) -> [(kind: String, sort: Double, count: Int)] {
        var found: [(String, Double, Int)] = []
        var handle: OpaquePointer?
        guard unsafe sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
        defer { unsafe sqlite3_close(handle) }
        var statement: OpaquePointer?
        unsafe sqlite3_prepare_v2(handle, "SELECT kind, sort, count FROM records", -1, &statement, nil)
        defer { unsafe sqlite3_finalize(statement) }
        while unsafe sqlite3_step(statement) == SQLITE_ROW {
            let kind = unsafe String(cString: sqlite3_column_text(statement, 0))
            found.append(
                (kind, unsafe sqlite3_column_double(statement, 1), Int(unsafe sqlite3_column_int64(statement, 2)))
            )
        }
        return found
    }

    @Test func `written: no kind's name, no time, no count in the file; read back as written, latest first`() throws {
        let file = path()
        defer { try? FileManager.default.removeItem(atPath: file) }
        let database = try #require(StateDatabase.open(at: file, key: key).database)
        let history = database.table("history")
        history.put("https://a.example/", payload: Data("a".utf8), sort: 100, count: 3)
        history.put("https://b.example/", payload: Data("b".utf8), sort: 200, count: 7)
        database.table("permissions").put("camera", payload: Data("allow".utf8))
        let read = history.all()
        #expect(read.rows.map(\.payload) == [Data("b".utf8), Data("a".utf8)])
        #expect(read.rows.map(\.sort) == [200, 100] && read.rows.map(\.count) == [7, 3])
        #expect(history.count() == 2 && database.table("permissions").count() == 1)
        database.close()
        let kept = columns(file)
        #expect(kept.count == 3)
        #expect(kept.allSatisfy { $0.sort == 0 && $0.count == 0 })
        #expect(kept.allSatisfy { !["history", "permissions"].contains($0.kind) }, "\(kept.map(\.kind))")
    }

    @Test func `removed by time: opened to find them, only those`() throws {
        let file = path()
        defer { try? FileManager.default.removeItem(atPath: file) }
        let database = try #require(StateDatabase.open(at: file, key: key).database)
        let history = database.table("history")
        for time in [100.0, 200, 300] { history.put("\(time)", payload: Data("\(time)".utf8), sort: time) }
        history.remove(sortBelow: 200)
        #expect(history.all().rows.map(\.sort) == [300, 200])
        history.remove(sortAtLeast: 300)
        #expect(history.all().rows.map(\.sort) == [200])
    }

    @Test
    func `a database of format 1 is resealed at its first opening; a record that does not open is left as it was`()
        throws
    {
        let file = path()
        defer { try? FileManager.default.removeItem(atPath: file) }
        try FormatOne.make(
            at: file,
            key: key,
            rows: [
                .init(kind: "history", name: "https://a.example/", payload: "a", sort: 100, count: 3),
                .init(kind: "history", name: "https://b.example/", payload: "b", sort: 200, count: 7),
                .init(kind: "permissions", name: "camera", payload: "allow", sort: 0, count: 0)
            ],
            damaged: ("history", "https://broken.example/")
        )
        let database = try #require(StateDatabase.open(at: file, key: key).database)
        #expect(database.version == 2)
        let history = database.table("history").all()
        #expect(history.rows.map(\.payload) == [Data("b".utf8), Data("a".utf8)] && history.rows.map(\.count) == [7, 3])
        #expect(history.unreadable == 1, "the damaged record is kept, still not opened")
        #expect(database.table("permissions").all().rows.map(\.payload) == [Data("allow".utf8)])
        database.close()
        let kept = columns(file)
        #expect(kept.count == 4 && kept.allSatisfy { $0.sort == 0 && $0.count == 0 && $0.kind != "history" })
        #expect(try #require(StateDatabase.open(at: file, key: key).database).table("history").count() == 3)
    }
}
