import Foundation
import Testing

@testable import SunsetStorage

/// What Settings say is kept (R12, roadmap 0030 step ST-6): each thing with its size, and the files that were set aside.
@Suite("What is kept, for Settings") struct StorageInventoryTests {
    let root = NSTemporaryDirectory() + "inventory-\(UUID().uuidString)"
    var places: StoragePlaces { StoragePlaces(environment: ["SUNSET_CONFIG": root + "/config.json"], home: "/nowhere") }

    func write(_ name: String, bytes: Int) throws {
        let path = root + "/" + name
        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        #expect(FileManager.default.createFile(atPath: path, contents: Data(repeating: 7, count: bytes)))
    }

    @Test func `an empty folder holds nothing, and says so without failing`() {
        let inventory = StorageInventory(places)
        #expect(inventory.documents == 0 && inventory.documentBytes == 0 && inventory.sessionBytes == 0)
        #expect(inventory.stateBytes == 0 && inventory.setAside.isEmpty)
    }

    @Test func `the documents are counted, the database with its journal, the session alone`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("Documents/\(UUID().uuidString).sealed", bytes: 100)
        try write("Documents/\(UUID().uuidString).sealed", bytes: 50)
        try write("Documents/.outgoing-x/Title.md", bytes: 999)
        try write("Documents/stray.txt", bytes: 999)
        try write("session.sealed", bytes: 30)
        try write("state.sqlite", bytes: 4096)
        try write("state.sqlite-wal", bytes: 1000)
        try write("library.sqlite", bytes: 2048)
        try write("config.json", bytes: 10)
        let inventory = StorageInventory(places)
        #expect(inventory.documents == 2 && inventory.documentBytes == 150 + 2048)
        #expect(inventory.sessionBytes == 30 && inventory.stateBytes == 5096)
    }

    @Test func `what did not read and was moved aside is listed, the latest first, and is not a document`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        let id = UUID().uuidString
        try write("session.sealed.damaged-2026-11-13T10-00-00", bytes: 5)
        try write("state.sqlite.damaged-2026-11-14T09-30-00", bytes: 6)
        try write("Documents/\(id).sealed.damaged-2026-11-12T08-00-00", bytes: 7)
        try write("Documents/\(id).sealed", bytes: 8)
        let inventory = StorageInventory(places)
        #expect(inventory.documents == 1)
        #expect(
            inventory.setAside.map(\.name) == [
                "state.sqlite.damaged-2026-11-14T09-30-00", "session.sealed.damaged-2026-11-13T10-00-00",
                "\(id).sealed.damaged-2026-11-12T08-00-00"
            ]
        )
        #expect(inventory.setAside.first?.path == root + "/state.sqlite.damaged-2026-11-14T09-30-00")
        #expect(inventory.setAside.first?.bytes == 6)
    }

    @Test func `a folder's size is what its files hold, however deep`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("web/a/b/one", bytes: 300)
        try write("web/two", bytes: 200)
        #expect(StorageInventory.size(of: [root + "/web", root + "/absent"]) == 500)
    }

    @Test
    func `the old plain files go to the Trash for the person's own setup when the setting says so, else are removed`() {
        let own = StoragePlaces(environment: [:], home: "/Users/someone")
        #expect(own.trashesImported(setting: true) && !own.trashesImported(setting: false))
        #expect(!places.trashesImported(setting: true), "a named setup's (a test's) never fill the Trash")
    }
}
