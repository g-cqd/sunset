import Foundation
import MarkdownLookKit
import Testing

@testable import SunsetDocuments

/// Edits are never forgotten without a word (roadmap 0023 step M-d): what closes a pane asks first, and a pane that goes by
/// a way that did not ask (a window closed by the system, a pane closed by code) leaves its document open, held by no pane,
/// until it is saved, given up, or the app is asked to quit, which names it.
@MainActor
@Suite("Unsaved edits outlive the panes that showed them")
struct OpenDocumentsKeepingTests {
    private let root: String = {
        let made = NSTemporaryDirectory() + "keeping-\(UUID().uuidString)"
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

    @Test func `edits nobody answered for stay when the last pane goes, and the file opens with them`() throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        type("unsaved\n", into: document)
        open.close(document)
        #expect(open.edited.map(\.title) == ["a.md"] && document.paneCount == 0)
        let again = open.open(.file(path))
        #expect(again === document && again.source.text == "one\nunsaved\n" && again.isEdited && again.paneCount == 1)
        try again.save()
        open.close(again)
        #expect(open.all.isEmpty && open.edited.isEmpty, "saved, it is forgotten with its last pane")
    }

    @Test func `edits given up are gone with the last pane, and the file is read again`() throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        let second = open.open(.file(path))
        type("unsaved\n", into: document)
        open.discard(document)
        open.close(document)
        #expect(open.all.count == 1, "a pane still shows it")
        open.close(second)
        #expect(open.all.isEmpty)
        let again = open.open(.file(path))
        #expect(again !== document && again.source.text == "one\n" && !again.isEdited)
    }

    @Test func `edits given up for a document no pane shows any more forget it at once`() throws {
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let document = open.open(.file(path))
        type("unsaved\n", into: document)
        open.close(document)
        open.discard(document)
        #expect(open.all.isEmpty)
    }

    @Test func `a document of the store that could not be kept stays too`() {
        let open = OpenDocuments(store: nil)
        let document = open.open(.stored(UUID()))
        type("text\n", into: document)
        open.close(document)
        #expect(open.edited.count == 1 && document.isStored)
    }

    @Test func `saving all writes every edited document and gives back the ones that could not be`() throws {
        let folder = root + "/locked"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        try "old\n".write(toFile: folder + "/b.md", atomically: true, encoding: .utf8)
        let path = try file("a.md", "one\n")
        let open = OpenDocuments(store: nil)
        let fine = open.open(.file(path))
        let stuck = open.open(.file(folder + "/b.md"))
        type("two\n", into: fine)
        type("new\n", into: stuck)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder) }
        let failed = open.saveAll()
        #expect(failed.map(\.title) == ["b.md"] && stuck.saveFailure != nil && fine.saveFailure == nil)
        #expect(!fine.isEdited && (try? String(contentsOfFile: path, encoding: .utf8)) == "one\ntwo\n")
    }
}
