import Foundation
import SQLite3
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// Roadmap 0091 A–B: a vault file holds nothing in the clear but ids and its version; a record opens only with its vault's
/// key, in its own place.
@Suite("A vault's file")
struct VaultFileTests {
    private func folder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test func `made 0600 in a 0700 folder; a record written reads back; nothing of it in the file's bytes`() throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appending(path: "Vaults/personal.vault").path
        let key = StorageKey.random()
        let vault = try VaultFile.create(at: path)
        let id = UUID()
        try vault.put(Data("hunter2 for bank.example".utf8), as: id, key: key)
        #expect(try vault.record(id, key: key) == Data("hunter2 for bank.example".utf8))
        #expect(vault.recordIDs == [id])
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        #expect((attributes[.posixPermissions] as? Int) == 0o600)
        let folderAttributes = try FileManager.default.attributesOfItem(
            atPath: (path as NSString).deletingLastPathComponent
        )
        #expect((folderAttributes[.posixPermissions] as? Int) == 0o700)
        let bytes = try Data(contentsOf: URL(filePath: path))
        #expect(bytes.range(of: Data("hunter2".utf8)) == nil && bytes.range(of: Data("bank.example".utf8)) == nil)
        let reopened = try VaultFile.open(at: path)
        let read = try reopened.record(id, key: key)
        #expect(reopened.id == vault.id && read == Data("hunter2 for bank.example".utf8))
    }

    @Test func `another key, another vault's record, or a record moved to another slot do not open`() throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let key = StorageKey.random()
        let first = try VaultFile.create(at: folder.appending(path: "a.vault").path)
        let second = try VaultFile.create(at: folder.appending(path: "b.vault").path)
        let (one, two) = (UUID(), UUID())
        try first.put(Data("one".utf8), as: one, key: key)
        try first.put(Data("two".utf8), as: two, key: key)
        #expect(throws: VaultFile.Failure.damaged) { try first.record(one, key: .random()) }
        // A record's sealed bytes copied into another slot, then into another vault.
        try first.plant(one, of: first, as: two)
        #expect(throws: VaultFile.Failure.damaged) { try first.record(two, key: key) }
        try second.plant(one, of: first, as: one)
        #expect(throws: VaultFile.Failure.damaged) { try second.record(one, key: key) }
        let none = try first.record(UUID(), key: key)
        #expect(none == nil)
    }

    @Test func `a file that is not a vault is refused; a removed record is gone`() throws {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appending(path: "x.vault").path
        try Data("not sqlite".utf8).write(to: URL(filePath: path))
        #expect(throws: VaultFile.Failure.self) { try VaultFile.open(at: path) }
        let vault = try VaultFile.create(at: folder.appending(path: "y.vault").path)
        let id = UUID()
        try vault.put(Data("x".utf8), as: id, key: .random())
        try vault.remove(id)
        #expect(vault.recordIDs.isEmpty)
    }
}
