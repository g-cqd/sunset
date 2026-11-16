import Foundation
import MarkdownLookKit
import SunsetStorage
import Testing

@testable import SunsetDocuments

/// A document saving itself (R6, roadmap 0023 step M-d): a file only when a setting says so (after a time, on losing focus),
/// both off by default; a document of Sunset's own store always ("kept by Sunset until saved"). It never writes over what it
/// has not read: a file changed on disk under these edits, a file that is gone, a file that is not text.
@MainActor
@Suite("A document saves itself only when it is safe and asked for")
struct DocumentAutosaveTests {
    private let root: String = {
        let made = NSTemporaryDirectory() + "autosave-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made, withIntermediateDirectories: true)
        return made
    }()
    private let soon = DocumentAutosave(
        fileDelay: .milliseconds(30),
        onFocusLoss: false,
        storedDelay: .milliseconds(30)
    )

    private func file(_ name: String, _ text: String) throws -> String {
        try text.write(toFile: root + "/" + name, atomically: true, encoding: .utf8)
        return root + "/" + name
    }

    private func read(_ path: String) -> String { (try? String(contentsOfFile: path, encoding: .utf8)) ?? "<none>" }

    private func type(_ text: String, into document: OpenDocument) {
        document.source.storage.replaceCharacters(
            in: NSRange(location: document.source.storage.length, length: 0),
            with: text
        )
    }

    private func store() throws -> DocumentStore {
        let key = try StorageKeyring(vault: MemoryKeyVault()).key()
        return DocumentStore(folder: root + "/Documents", library: nil, key: key, problems: StorageProblems()) { url in
            try FileManager.default.removeItem(at: url)
        }
    }

    private func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0 ..< 200 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
        return condition()
    }

    @Test func `by default a file is written only when asked`() async throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        #expect(open.autosave == DocumentAutosave() && open.autosave.fileDelay == nil && !open.autosave.onFocusLoss)
        let document = open.open(.file(path))
        type("two\n", into: document)
        document.focusLost()
        try await Task.sleep(for: .milliseconds(120))
        #expect(document.isEdited && read(path) == "one\n")
    }

    @Test func `with a time set, a file is written that long after its first edit, and again after the next`()
        async throws
    {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        open.autosave = soon
        let document = open.open(.file(path))
        type("two\n", into: document)
        #expect(document.isEdited && read(path) == "one\n", "not at the key")
        #expect(await eventually { !document.isEdited })
        #expect(read(path) == "one\ntwo\n")
        type("three\n", into: document)
        #expect(await eventually { !document.isEdited })
        #expect(read(path) == "one\ntwo\nthree\n")
    }

    @Test func `the time is taken when the edit is made: a setting changed later holds for the next edit`() async throws
    {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        type("two\n", into: document)
        open.autosave = soon
        try await Task.sleep(for: .milliseconds(100))
        #expect(document.isEdited, "it was edited while no time was set")
        type("three\n", into: document)
        #expect(await eventually { !document.isEdited })
    }

    @Test func `on losing focus a file is written when that is set, at once`() throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        open.autosave = DocumentAutosave(fileDelay: nil, onFocusLoss: true)
        let document = open.open(.file(path))
        let other = open.open(.file(try file("b.md", "b\n")))
        type("two\n", into: document)
        type("more\n", into: other)
        document.focusLost()
        #expect(!document.isEdited && read(path) == "one\ntwo\n")
        #expect(other.isEdited, "only the one that lost it")
        open.focusLost()
        #expect(!other.isEdited, "the app went to the back: every one")
    }

    @Test func `it never writes over a file that changed on disk under the edits`() async throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        open.autosave = DocumentAutosave(fileDelay: .milliseconds(30), onFocusLoss: true)
        let document = open.open(.file(path))
        type("mine\n", into: document)
        try "theirs\n".write(toFile: path, atomically: true, encoding: .utf8)
        document.checkFile()
        #expect(document.changedOnDisk)
        document.focusLost()
        try await Task.sleep(for: .milliseconds(120))
        #expect(read(path) == "theirs\n" && document.isEdited)
        document.keepEdits()
        document.focusLost()
        #expect(read(path) == "one\nmine\n", "the person chose these edits: they are written again")
    }

    @Test func `it does not make again a file that was deleted, nor write one it could not read`() async throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        open.autosave = DocumentAutosave(fileDelay: .milliseconds(30), onFocusLoss: true)
        let document = open.open(.file(path))
        type("two\n", into: document)
        try FileManager.default.removeItem(atPath: path)
        document.checkFile()
        document.focusLost()
        try await Task.sleep(for: .milliseconds(120))
        #expect(!FileManager.default.fileExists(atPath: path) && document.isEdited)
        try document.save()
        #expect(read(path) == "one\ntwo\n", "asked for, it is")
    }

    @Test func `a save that fails by itself is said once and tried again after the next edit`() async throws {
        let folder = root + "/locked"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let path = folder + "/a.md"
        try "one\n".write(toFile: path, atomically: true, encoding: .utf8)
        let open = OpenDocuments(store: nil)
        open.autosave = soon
        let document = open.open(.file(path))
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder) }
        type("two\n", into: document)
        #expect(await eventually { document.saveFailure != nil })
        #expect(document.isEdited && read(path) == "one\n")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder)
        type("three\n", into: document)
        #expect(await eventually { !document.isEdited })
        #expect(document.saveFailure == nil && read(path) == "one\ntwo\nthree\n")
    }

    @Test func `a document of the store keeps itself: after a moment, and when its last pane goes`() async throws {
        let store = try store()
        let made = try store.create(kind: .markdown)
        let open = OpenDocuments(store: store)
        open.autosave.storedDelay = .milliseconds(30)
        let document = open.open(.stored(made.id))
        type("# Kept\n", into: document)
        #expect(await eventually { !document.isEdited })
        #expect(try store.text(of: made.id) == "# Kept\n")

        open.autosave.storedDelay = .seconds(60)
        type("more\n", into: document)
        #expect(document.isEdited && document.keepsItself, "edited, and nothing to ask: it is kept when it goes")
        document.saveFailure = "Not saved: the disk is full."
        #expect(!document.keepsItself, "once keeping it has failed, it is asked about like a file")
        document.saveFailure = nil
        open.close(document)
        #expect(try store.text(of: made.id) == "# Kept\nmore\n", "nothing asked, nothing lost")
    }

    @Test func `quitting keeps every document of the store, and no file`() throws {
        let store = try store()
        let made = try store.create(kind: .markdown)
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: store)
        let stored = open.open(.stored(made.id))
        let onDisk = open.open(.file(path))
        type("kept\n", into: stored)
        type("two\n", into: onDisk)
        open.keepStored()
        #expect(try store.text(of: made.id) == "kept\n" && !stored.isEdited)
        #expect(onDisk.isEdited && read(path) == "one\n")
    }
}
