import Foundation
import SunsetStorage
import SunsetTestSupport
import Testing

@testable import SunsetDocuments

/// A document of Sunset's own store keeps itself, unlike a file.
extension DocumentAutosaveTests {
    @Test func `a document of the store keeps itself: after a moment, and when its last pane goes`() async throws {
        let store = try store()
        let made = try store.create(kind: .markdown)
        let open = documents(store: store)
        open.autosave.storedDelay = .milliseconds(30)
        let document = open.open(.stored(made.id))
        let mark = time.mark()
        type("# Kept\n", into: document)
        try await time.release(after: .milliseconds(30), since: mark)
        #expect(!document.isEdited)
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
        let open = documents(store: store)
        let stored = open.open(.stored(made.id))
        let onDisk = open.open(.file(path))
        type("kept\n", into: stored)
        type("two\n", into: onDisk)
        open.keepStored()
        #expect(try store.text(of: made.id) == "kept\n" && !stored.isEdited)
        #expect(onDisk.isEdited && read(path) == "one\n")
    }
}
