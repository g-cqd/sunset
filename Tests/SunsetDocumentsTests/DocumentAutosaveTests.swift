import Foundation
import MarkdownLookKit
import SunsetStorage
import SunsetTestSupport
import Testing

@testable import SunsetDocuments

/// A document saving itself: a file only when a setting says so (after a time, on losing focus), both off by default; a
/// document of Sunset's own store always ("kept by Sunset until saved"). It never writes over what it has not read: a file
/// changed on disk under these edits, a file that is gone, a file that is not text.
@MainActor
@Suite("A document saves itself only when it is safe and asked for")
struct DocumentAutosaveTests {
    let root: String = {
        let made = NSTemporaryDirectory() + "autosave-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made, withIntermediateDirectories: true)
        return made
    }()
    let soon = DocumentAutosave(
        fileDelay: .milliseconds(30),
        onFocusLoss: false,
        storedDelay: .milliseconds(30)
    )

    func file(_ name: String, _ text: String) throws -> String {
        try text.write(toFile: root + "/" + name, atomically: true, encoding: .utf8)
        return root + "/" + name
    }

    func read(_ path: String) -> String {
        (try? String(contentsOfFile: path, encoding: .utf8)) ?? "<none>"
    }

    func type(_ text: String, into document: OpenDocument) {
        document.source.storage.replaceCharacters(
            in: NSRange(location: document.source.storage.length, length: 0),
            with: text
        )
    }

    func store() throws -> DocumentStore {
        let key = try StorageKeyring(vault: MemoryKeyVault()).key()
        return DocumentStore(folder: root + "/Documents", library: nil, key: key, problems: StorageProblems()) { url in
            try FileManager.default.removeItem(at: url)
        }
    }

    /// The time of the documents' saves: nothing waits on the wall clock.
    let time = TestTime()

    func documents(store: DocumentStore? = nil) -> OpenDocuments {
        let open = OpenDocuments(store: store)
        open.runtime = time.runtime
        return open
    }

    @Test func `by default a file is written only when asked`() async throws {
        let path = try file("a.md", "one\n")
        let open = documents()
        #expect(open.autosave == DocumentAutosave() && open.autosave.fileDelay == nil && !open.autosave.onFocusLoss)
        let document = open.open(.file(path))
        type("two\n", into: document)
        document.focusLost()
        try await time.pass(.seconds(60))
        #expect(document.isEdited && read(path) == "one\n")
    }

    @Test func `with a time set, a file is written that long after its first edit, and again after the next`()
        async throws
    {
        let path = try file("a.md", "one\n")
        let open = documents()
        open.autosave = soon
        let document = open.open(.file(path))
        var mark = time.mark()
        type("two\n", into: document)
        #expect(document.isEdited && read(path) == "one\n", "not at the key")
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!document.isEdited && read(path) == "one\ntwo\n")
        mark = time.mark()
        type("three\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!document.isEdited)
        #expect(read(path) == "one\ntwo\nthree\n")
    }

    @Test func `the time is taken when the edit is made: a setting changed later holds for the next edit`() async throws
    {
        let path = try file("a.md", "one\n")
        let open = documents()
        let document = open.open(.file(path))
        type("two\n", into: document)
        open.autosave = soon
        try await time.pass(.seconds(60))
        #expect(document.isEdited, "it was edited while no time was set")
        let mark = time.mark()
        type("three\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!document.isEdited)
    }

    @Test func `on losing focus a file is written when that is set, at once`() throws {
        let path = try file("a.md", "one\n")
        let open = documents()
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

    @Test func `it never writes over a block that changed on disk under the edits, until the person has answered`()
        async throws
    {
        let path = try file("a.md", "one\n")
        let open = documents()
        open.autosave = DocumentAutosave(fileDelay: .milliseconds(30), onFocusLoss: true)
        let document = open.open(.file(path))
        let mark = time.mark()
        type("mine\n", into: document)
        try "theirs\n".write(toFile: path, atomically: true, encoding: .utf8)
        document.checkFile()
        #expect(document.conflicts.count == 1)
        document.focusLost()
        type("more\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(read(path) == "theirs\n" && document.isEdited)
        document.resolve(try #require(document.conflicts.first).id, keeping: .mine)
        document.focusLost()
        #expect(read(path) == "one\nmine\nmore\n", "the person chose these edits: they are written again")
    }

    @Test
    func `it never writes over a file that stopped being text under the edits, until the person says to keep them`()
        async throws
    {
        let path = try file("b.md", "one\n")
        let open = documents()
        open.autosave = DocumentAutosave(fileDelay: .milliseconds(30), onFocusLoss: true)
        let document = open.open(.file(path))
        let mark = time.mark()
        type("mine\n", into: document)
        try Data([0xFF, 0xFE, 0x00]).write(to: URL(fileURLWithPath: path))
        document.checkFile()
        #expect(document.changedOnDisk)
        document.focusLost()
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(FileManager.default.contents(atPath: path) == Data([0xFF, 0xFE, 0x00]) && document.isEdited)
        document.keepEdits()
        document.focusLost()
        #expect(read(path) == "one\nmine\n", "the person chose these edits: they are written again")
    }

    @Test func `it does not make again a file that was deleted, nor write one it could not read`() async throws {
        let path = try file("a.md", "one\n")
        let open = documents()
        open.autosave = DocumentAutosave(fileDelay: .milliseconds(30), onFocusLoss: true)
        let document = open.open(.file(path))
        let mark = time.mark()
        type("two\n", into: document)
        try FileManager.default.removeItem(atPath: path)
        document.checkFile()
        document.focusLost()
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!FileManager.default.fileExists(atPath: path) && document.isEdited)
        try document.save()
        #expect(read(path) == "one\ntwo\n", "asked for, it is")
    }

    @Test func `a save that fails by itself is said once and tried again after the next edit`() async throws {
        let folder = root + "/locked"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let path = folder + "/a.md"
        try "one\n".write(toFile: path, atomically: true, encoding: .utf8)
        let open = documents()
        open.autosave = soon
        let document = open.open(.file(path))
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder) }
        var mark = time.mark()
        type("two\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(document.saveFailure != nil)
        #expect(document.isEdited && read(path) == "one\n")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder)
        mark = time.mark()
        type("three\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!document.isEdited)
        #expect(document.saveFailure == nil && read(path) == "one\ntwo\nthree\n")
    }
}
