import Foundation
import SunsetStorage
import Testing

@testable import SunsetDocuments

@MainActor
@Suite("The store of documents that live in Sunset")
struct DocumentStoreTests {
    private let key = try? StorageKeyring(vault: MemoryKeyVault()).key()
    private let root = NSTemporaryDirectory() + "documents-\(UUID().uuidString)"

    /// A store on the test's folder; what it puts away is kept in `discarded` (name and text) instead of the Trash.
    private func open(
        _ discarded: Discarded = Discarded(),
        problems: StorageProblems = StorageProblems()
    ) throws -> DocumentStore {
        let key = try #require(key)
        let library = StateDatabase.open(at: root + "/library.sqlite", key: key).database
        return DocumentStore(folder: root + "/Documents", library: library, key: key, problems: problems) { url in
            discarded.files.append((url.lastPathComponent, (try? String(contentsOf: url, encoding: .utf8)) ?? ""))
            try FileManager.default.removeItem(at: url)
        }
    }

    final class Discarded {
        var files: [(name: String, text: String)] = []
    }

    @Test func `a document is named by its content: its first heading, else its first line, else Untitled`() {
        #expect(
            DocumentTitle.of("intro\n\n## Tides of the North Sea ##\n", kind: .markdown) == "Tides of the North Sea"
        )
        #expect(DocumentTitle.of("\n\n  first line here  \nsecond", kind: .markdown) == "first line here")
        #expect(DocumentTitle.of("# not a heading in text", kind: .text) == "# not a heading in text")
        #expect(
            DocumentTitle.of("  \n\n", kind: .markdown) == "Untitled"
                && DocumentTitle.of("", kind: .mermaid) == "Untitled"
        )
        #expect(DocumentTitle.of(String(repeating: "x", count: 300), kind: .text).count == DocumentTitle.limit)
        #expect(DocumentTitle.fileName("a/b: c?", kind: .markdown) == "a-b- c?.md")
        #expect(DocumentTitle.fileName("Untitled", kind: .mermaid) == "Untitled.mmd")
    }

    @Test func `a new document is kept sealed, listed, read back, and renamed as its text changes`() throws {
        let store = try open()
        let made = try store.create()
        #expect(made.title == "Untitled" && made.kind == .markdown && store.documents.map(\.id) == [made.id])
        try store.save("# Harbour notes\n\nLow tide at six.\n", to: made.id)
        #expect(try store.text(of: made.id) == "# Harbour notes\n\nLow tide at six.\n")
        #expect(store.documents.first?.title == "Harbour notes")
        let file = try #require(FileManager.default.contents(atPath: root + "/Documents/\(made.id.uuidString).sealed"))
        #expect(Seal.isSealed(file) && file.range(of: Data("Harbour".utf8)) == nil)
        let library =
            (FileManager.default.contents(atPath: root + "/library.sqlite") ?? Data())
            + (FileManager.default.contents(atPath: root + "/library.sqlite-wal") ?? Data())
        #expect(library.range(of: Data("Harbour".utf8)) == nil, "the index holds no title in the clear")
    }

    @Test func `the store is the same after a reopen: titles, kinds, the latest changed first`() throws {
        do {
            let store = try open()
            let first = try store.create(text: "# First\n")
            _ = try store.create(kind: .mermaid, text: "flowchart LR\n  A --> B\n")
            try store.save("# First, edited\n", to: first.id)
        }
        let again = try open()
        #expect(again.documents.map(\.title) == ["First, edited", "flowchart LR"])
        #expect(again.documents.map(\.kind) == [.markdown, .mermaid])
    }

    @Test func `the index is rebuilt from the files when it is lost, and follows them when it disagrees`() throws {
        let id: UUID
        do {
            let store = try open()
            id = try store.create(text: "# Kept\n").id
            _ = try store.create(text: "# Dropped later\n")
        }
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: root + "/library.sqlite" + suffix)
        }
        let rebuilt = try open()
        #expect(Set(rebuilt.documents.map(\.title)) == ["Kept", "Dropped later"])
        // A file that went, and one that appeared, behind the index's back.
        let dropped = try #require(rebuilt.documents.first { $0.title == "Dropped later" })
        try FileManager.default.removeItem(atPath: root + "/Documents/\(dropped.id.uuidString).sealed")
        let follows = try open()
        #expect(follows.documents.map(\.id) == [id])
    }

    @Test func `deleting puts the document away as plain text under its name, and takes it out of the store`() throws {
        let discarded = Discarded()
        let store = try open(discarded)
        let made = try store.create(text: "# Tide: table / 2026\n\nrows\n")
        try store.delete(made.id)
        #expect(discarded.files.count == 1 && discarded.files[0].name == "Tide- table - 2026.md")
        #expect(discarded.files[0].text == "# Tide: table / 2026\n\nrows\n")
        #expect(store.documents.isEmpty)
        #expect(try open().documents.isEmpty)
        let left = try FileManager.default.contentsOfDirectory(atPath: root + "/Documents")
            .filter { !$0.hasPrefix(".") }
        #expect(left.isEmpty)
        #expect(throws: DocumentStoreFailure.missing) { try store.text(of: made.id) }
    }

    @Test func `moving to a file writes the plain text there and takes the document out of the store`() throws {
        let store = try open()
        let made = try store.create(kind: .text, text: "plain words\n")
        let target = URL(fileURLWithPath: root + "/out/words.txt")
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try store.move(made.id, to: target)
        #expect(try String(contentsOf: target, encoding: .utf8) == "plain words\n" && store.documents.isEmpty)
    }

    @Test func `a damaged document is set aside and said; the others are there`() throws {
        let problems = StorageProblems()
        let bad: UUID
        do {
            let store = try open()
            bad = try store.create(text: "# Will break\n").id
            _ = try store.create(text: "# Fine\n")
        }
        let path = root + "/Documents/\(bad.uuidString).sealed"
        var bytes = try #require(FileManager.default.contents(atPath: path))
        bytes[bytes.count - 2] ^= 1
        try bytes.write(to: URL(fileURLWithPath: path))
        let store = try open(problems: problems)
        #expect(store.documents.map(\.title) == ["Fine"])
        #expect(problems.items.count == 1 && problems.items[0].kind == .damaged)
        #expect(problems.items[0].what == "The document \u{201C}Will break\u{201D}")
        #expect(problems.items[0].movedTo?.contains(".sealed.damaged-") == true)
    }
}
