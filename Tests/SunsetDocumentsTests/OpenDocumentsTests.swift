import Foundation
import MarkdownLookKit
import SunsetStorage
import Testing

@testable import SunsetDocuments

@MainActor
@Suite("The document behind a pane: one per file for the whole app")
struct OpenDocumentsTests {
    private let root: String = {
        let made = NSTemporaryDirectory() + "open-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made, withIntermediateDirectories: true)
        return made
    }()

    private func file(_ name: String, _ text: String) throws -> String {
        try text.write(toFile: root + "/" + name, atomically: true, encoding: .utf8)
        return root + "/" + name
    }

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

    /// Waits until `condition` holds (a change on disk is told by a thread of its own).
    private func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0 ..< 200 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
        return condition()
    }

    @Test func `a file is one document however it is named: its path, a link to it, a path with dots`() throws {
        let path = try file("notes.md", "# Notes\n")
        try FileManager.default.createSymbolicLink(atPath: root + "/link.md", withDestinationPath: path)
        let open = OpenDocuments(store: nil)
        let one = open.open(.file(path))
        let two = open.open(.file(root + "/link.md"))
        let three = open.open(.file(root + "/./sub/../notes.md"))
        #expect(one === two && two === three && open.all.count == 1)
        type("more\n", into: one)
        #expect(two.source.text == "# Notes\nmore\n" && three.isEdited)
    }

    @Test func `a document stays while a pane holds it, and is read again after the last lets go`() throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let first = open.open(.file(path))
        _ = open.open(.file(path))
        type("unsaved", into: first)
        open.close(first)
        #expect(open.all.count == 1 && open.document(at: .file(path)) === first)
        open.close(first)
        #expect(open.all.isEmpty && open.document(at: .file(path)) == nil)
        #expect(open.open(.file(path)).source.text == "one\n", "what was not saved is gone with its last pane")
    }

    @Test func `the kind comes from the file's name, the title is the file's name`() throws {
        let open = OpenDocuments(store: nil)
        #expect(open.open(.file(try file("a.md", ""))).kind == .markdown)
        #expect(open.open(.file(try file("b.MARKDOWN", ""))).kind == .markdown)
        #expect(open.open(.file(try file("c.mmd", "flowchart LR\n"))).kind == .mermaid)
        #expect(open.open(.file(try file("c.mmd", ""))).source.content == .diagram)
        #expect(
            open.open(.file(try file("Makefile", "all:\n"))).source.content == .plain,
            "text is not read as Markdown"
        )
        #expect(open.open(.file(try file("Makefile", "all:\n"))).kind == .text)
        #expect(open.open(.file(try file("d.swift", ""))).title == "d.swift")
    }

    @Test func `saving writes the file whole, keeps its permissions, and the document is no longer edited`() throws {
        let path = try file("s.md", "before\n")
        try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: path)
        let document = OpenDocuments(store: nil).open(.file(path))
        type("after\n", into: document)
        #expect(document.isEdited)
        try document.save()
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "before\nafter\n" && !document.isEdited)
        #expect(try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int == 0o640)
        let left = try FileManager.default.contentsOfDirectory(atPath: root).filter { $0 != "s.md" }
        #expect(left.isEmpty, "no temporary file is left: \(left)")
    }

    @Test func `a file that is not there opens empty and is made by saving`() throws {
        let path = root + "/new.md"
        let document = OpenDocuments(store: nil).open(.file(path))
        #expect(document.problem == .missing && document.source.text.isEmpty && !document.isEdited)
        type("# New\n", into: document)
        try document.save()
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "# New\n" && document.problem == nil)
    }

    @Test func `a file that is not text is shown and cannot be saved over`() throws {
        let path = root + "/blob.bin"
        try Data([0x66, 0x6f, 0xff, 0xfe, 0x00, 0x6f]).write(to: URL(fileURLWithPath: path))
        let document = OpenDocuments(store: nil).open(.file(path))
        #expect(document.problem == .notText && document.kind == .text)
        type("x", into: document)
        #expect(throws: OpenDocumentFailure.readOnly) { try document.save() }
        #expect(FileManager.default.contents(atPath: path) == Data([0x66, 0x6f, 0xff, 0xfe, 0x00, 0x6f]))
    }

    @Test func `a change on disk is taken when nothing was edited here, and our own save is not a change`() async throws
    {
        let path = try file("w.md", "first\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        document.source.apply(MarkdownEdit(range: 6 ..< 6, replacement: "mine\n", selection: 11 ..< 11))
        try document.save()
        let revision = document.source.revision
        // The file as we wrote it, told as a change: nothing is read again, and the undo history is whole.
        document.fileChanged(.read(path))
        #expect(document.source.revision == revision && document.source.undoManager.canUndo)
        try "second\n".write(toFile: path, atomically: true, encoding: .utf8)
        #expect(await eventually { document.source.text == "second\n" })
        #expect(!document.isEdited && !document.changedOnDisk && document.source.revision == revision + 1)
        open.close(document)
    }

    @Test func `a change that keeps the file's length and its beginning is still a change`() throws {
        let long = String(repeating: "a line of the file\n", count: 20)
        let path = try file("same.md", long)
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        var changed = Array(long.utf8)
        changed[changed.count - 3] = UInt8(ascii: "X")
        try Data(changed).write(to: URL(fileURLWithPath: path))
        document.fileChanged(.read(path))
        #expect(document.source.text == String(decoding: changed, as: UTF8.self))
        open.close(document)
    }

    @Test func `a change on disk while edited here is kept apart and said, not taken`() async throws {
        let path = try file("c.md", "base\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        type("mine\n", into: document)
        try "theirs\n".write(toFile: path, atomically: true, encoding: .utf8)
        #expect(await eventually { document.changedOnDisk })
        #expect(document.source.text == "base\nmine\n" && document.isEdited)
        // The file deleted: the text stays, and it is said.
        try FileManager.default.removeItem(atPath: path)
        #expect(await eventually { document.problem == .missing })
        #expect(document.source.text == "base\nmine\n")
        open.close(document)
    }

    @Test func `a document of the store is one document too, named by its content, saved into the store`() throws {
        let store = try store()
        let made = try store.create(text: "# Harbour\n")
        let open = OpenDocuments(store: store)
        let document = open.open(.stored(made.id))
        #expect(open.open(.stored(made.id)) === document && document.kind == .markdown && document.title == "Harbour")
        document.source.reload(text: "# Harbour notes\n\ntide\n")
        type("more\n", into: document)
        #expect(document.title == "Harbour notes" && document.isEdited)
        try document.save()
        #expect(try store.text(of: made.id) == "# Harbour notes\n\ntide\nmore\n" && !document.isEdited)
        #expect(store.documents.first?.title == "Harbour notes")
        #expect(OpenDocuments(store: store).open(.stored(UUID())).problem == .missing)
    }

    @Test func `a place is kept in a pane's saved state and read back`() {
        let id = UUID()
        #expect(DocumentPlace(state: DocumentPlace.file("/tmp/a.md").state) == .file("/tmp/a.md"))
        #expect(DocumentPlace(state: DocumentPlace.stored(id).state) == .stored(id))
        #expect(DocumentPlace(state: [:]) == nil && DocumentPlace(state: ["document": "not an id"]) == nil)
    }
}
