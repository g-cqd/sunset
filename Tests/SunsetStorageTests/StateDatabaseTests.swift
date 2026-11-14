import Foundation
import Testing

@testable import SunsetStorage

@MainActor
@Suite("The database of small records: versioned, sealed row by row, set aside when it does not read")
struct StateDatabaseTests {
    private let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0) }))
    private let noon = Date(timeIntervalSince1970: 1_794_571_200)

    private func folder() -> String {
        let path = NSTemporaryDirectory() + "state-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    @Test func `a new database is made with the current version; records are kept across a reopen`() throws {
        let path = folder() + "/state.sqlite"
        do {
            let opened = StateDatabase.open(at: path, key: key)
            let database = try #require(opened.database)
            #expect(opened.problem == nil && database.version == StateDatabase.currentVersion)
            let table = database.table("history")
            table.put("https://a.com/", payload: Data("A".utf8), sort: 2, count: 3)
            table.put("https://b.com/", payload: Data("B".utf8), sort: 1)
            table.put("https://a.com/", payload: Data("A2".utf8), sort: 5, count: 4)
            #expect(table.count() == 2)
        }
        let again = try #require(StateDatabase.open(at: path, key: key).database)
        let rows = again.table("history").all()
        #expect(rows.unreadable == 0)
        #expect(rows.rows.map(\.payload) == [Data("A2".utf8), Data("B".utf8)], "latest sort first")
        #expect(rows.rows.first?.sort == 5 && rows.rows.first?.count == 4)
        #expect(again.table("zoom").all().rows.isEmpty, "kinds do not see each other")
    }

    @Test func `nothing of a record is in the file in the clear, not even what names it`() throws {
        let path = folder() + "/state.sqlite"
        do {
            let database = try #require(StateDatabase.open(at: path, key: key).database)
            database.table("history").put("https://secret.example/path", payload: Data("Secret Title".utf8))
        }
        var bytes = try #require(FileManager.default.contents(atPath: path))
        bytes += FileManager.default.contents(atPath: path + "-wal") ?? Data()
        #expect(
            bytes.range(of: Data("secret.example".utf8)) == nil && bytes.range(of: Data("Secret Title".utf8)) == nil
        )
    }

    @Test func `removing: one record, those from a time on, those before a time, all`() throws {
        let database = try #require(StateDatabase.open(at: ":memory:", key: key).database)
        let table = database.table("history")
        for (index, name) in ["a", "b", "c", "d"].enumerated() {
            table.put(name, payload: Data(name.utf8), sort: Double(index))
        }
        table.remove("b")
        #expect(table.all().rows.map(\.payload) == ["d", "c", "a"].map { Data($0.utf8) })
        table.remove(sortBelow: 1)
        table.remove(sortAtLeast: 3)
        #expect(table.all().rows.map(\.payload) == [Data("c".utf8)])
        table.removeAll()
        #expect(table.count() == 0)
    }

    @Test func `many records are written as one transaction`() throws {
        let database = try #require(StateDatabase.open(at: ":memory:", key: key).database)
        let table = database.table("history")
        database.transaction {
            for index in 0 ..< 500 { table.put("u\(index)", payload: Data("p".utf8), sort: Double(index)) }
        }
        #expect(table.count() == 500)
    }

    @Test func `a file that is not a database is set aside and said, and a new one is made`() throws {
        let folder = folder()
        let path = folder + "/state.sqlite"
        try Data("this is not a database, at all, not even close".utf8).write(to: URL(fileURLWithPath: path))
        let opened = StateDatabase.open(at: path, key: key, now: noon)
        #expect(opened.database != nil)
        let problem = try #require(opened.problem)
        #expect(problem.what == "Sunset's database of history and site settings" && problem.kind == .damaged)
        let aside = try #require(problem.movedTo)
        #expect(aside.contains("state.sqlite.damaged-2026-11-13") && FileManager.default.fileExists(atPath: aside))
    }

    @Test func `a database sealed with another key is left as it is: locked, not replaced`() throws {
        let path = folder() + "/state.sqlite"
        do {
            let database = try #require(StateDatabase.open(at: path, key: key).database)
            database.table("history").put("u", payload: Data("p".utf8))
        }
        let other = StorageKey(bytes: Data(repeating: 9, count: 32))
        let opened = StateDatabase.open(at: path, key: other)
        #expect(opened.database == nil && opened.problem?.kind == .locked && opened.problem?.movedTo == nil)
        #expect(FileManager.default.fileExists(atPath: path))
        #expect(try #require(StateDatabase.open(at: path, key: key).database).table("history").count() == 1)
    }

    @Test func `a database written by a later Sunset is set aside, not read as this version's`() throws {
        let folder = folder()
        let path = folder + "/state.sqlite"
        do {
            let database = try #require(StateDatabase.open(at: path, key: key).database)
            database.setVersionForTesting(StateDatabase.currentVersion + 1)
        }
        let opened = StateDatabase.open(at: path, key: key, now: noon)
        #expect(opened.problem?.kind == .damaged && opened.database?.table("history").count() == 0)
    }

    @Test func `a row that does not open is counted, not given, and the others are read`() throws {
        let database = try #require(StateDatabase.open(at: ":memory:", key: key).database)
        let table = database.table("history")
        table.put("good", payload: Data("g".utf8))
        database.corruptForTesting(kind: "history")
        table.put("other", payload: Data("o".utf8), sort: 1)
        let read = table.all()
        #expect(read.unreadable == 1 && read.rows.map(\.payload) == [Data("o".utf8)])
    }
}
