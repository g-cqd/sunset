import Foundation
import SunsetStorage
import Testing

@testable import SunsetDocuments

/// Every document out of the store as a plain file (R12 step ST-6). They stay in the store: an export is a copy.
@MainActor @Suite("Exporting every document") struct DocumentStoreExportTests {
    private let key = try? StorageKeyring(vault: MemoryKeyVault()).key()
    private let root = NSTemporaryDirectory() + "export-documents-\(UUID().uuidString)"

    private func open() throws -> DocumentStore {
        let key = try #require(key)
        let library = StateDatabase.open(at: root + "/library.sqlite", key: key).database
        return DocumentStore(folder: root + "/Documents", library: library, key: key) {
            try FileManager.default.removeItem(at: $0)
        }
    }

    @Test func `each document is a plain file named by its title; two of one title do not write over each other`()
        throws
    {
        defer { try? FileManager.default.removeItem(atPath: root) }
        let store = try open()
        try store.create(text: "# Tides\n\nSix.\n")
        try store.create(text: "# Tides\n\nSeven.\n")
        try store.create(kind: .text, text: "a/b: c\n")
        try store.create(kind: .mermaid, text: "")
        let folder = URL(fileURLWithPath: root + "/out")
        let result = store.exportAll(to: folder)
        #expect(result.written == 4 && result.failed.isEmpty && store.documents.count == 4, "they stay in the store")
        let names = try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted()
        #expect(names == ["Tides 2.md", "Tides.md", "Untitled.mmd", "a-b- c.txt"])
        let texts = try ["Tides.md", "Tides 2.md"]
            .map { try String(contentsOf: folder.appending(path: $0), encoding: .utf8) }
        #expect(Set(texts) == ["# Tides\n\nSix.\n", "# Tides\n\nSeven.\n"])
        let mode =
            try FileManager.default.attributesOfItem(atPath: folder.appending(path: "Tides.md").path)[.posixPermissions]
        #expect(mode as? Int == 0o600)
    }

    @Test func `a document that does not read is said by its title, and the others are written`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        let store = try open()
        let bad = try store.create(text: "# Broken\n")
        try store.create(text: "# Fine\n")
        try Data("not sealed".utf8)
            .write(to: URL(fileURLWithPath: root + "/Documents/" + bad.id.uuidString + ".sealed"))
        let result = store.exportAll(to: URL(fileURLWithPath: root + "/out"))
        #expect(result.written == 1 && result.failed == ["Broken"], "\(result)")
    }
}
