import Foundation
import Testing

@testable import SunsetStorage

/// An audit (2026-11-18) found the folder and the databases readable by others (0755, 0644), and the write-ahead log
/// kept megabytes of what was written and deleted.
@MainActor
@Suite("The database's files: its owner's only, no residue")
struct StateDatabaseHardeningTests {
    private let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0) }))

    private func mode(_ path: String) -> Int {
        ((try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions]) as? Int ?? -1) & 0o777
    }

    @Test func `the folder is 0700 and the database, its log and its index 0600`() throws {
        let folder = NSTemporaryDirectory() + "hardening-\(UUID().uuidString)"
        let path = folder + "/state.sqlite"
        let database = try #require(StateDatabase.open(at: path, key: key).database)
        database.table("history").put("https://a.example/", payload: Data("A".utf8), sort: 1)
        #expect(mode(folder) == 0o700, "folder \(String(mode(folder), radix: 8))")
        for file in [path, path + "-wal", path + "-shm"] where FileManager.default.fileExists(atPath: file) {
            #expect(mode(file) == 0o600, "\(file): \(String(mode(file), radix: 8))")
        }
    }

    @Test func `deleted records are overwritten, and the log is emptied when the database closes`() throws {
        let folder = NSTemporaryDirectory() + "hardening-\(UUID().uuidString)"
        let path = folder + "/state.sqlite"
        do {
            let database = try #require(StateDatabase.open(at: path, key: key).database)
            #expect(database.number("PRAGMA secure_delete") == 1)
            let table = database.table("history")
            for index in 0 ..< 200 {
                table.put("https://site\(index).example/", payload: Data(repeating: 7, count: 400), sort: 1)
            }
            table.removeAll()
            database.close()
        }
        let log = (try? FileManager.default.attributesOfItem(atPath: path + "-wal")[.size]) as? Int ?? 0
        #expect(log == 0, "\(log) bytes left in the log")
    }
}
