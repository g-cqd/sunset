import Foundation
import MarkdownLookKit
import SunsetDocuments
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// A document as the content of a pane (roadmap 0023 step M-c).
@MainActor
@Suite("A document in a pane")
struct DocumentContentTests {
    let root: String = {
        let made = NSTemporaryDirectory() + "pane-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made, withIntermediateDirectories: true)
        return (try? URL(fileURLWithPath: made).resourceValues(forKeys: [.canonicalPathKey]).canonicalPath) ?? made
    }()
    let documents = OpenDocuments(store: nil)

    func file(_ name: String, _ text: String) throws -> String {
        try text.write(toFile: root + "/" + name, atomically: true, encoding: .utf8)
        return root + "/" + name
    }

    func content(_ path: String, mode: String? = nil) throws -> DocumentContent {
        var state = ["file": path]
        state["view"] = mode
        return try #require(
            DocumentContent(PaneDescriptor(kind: DocumentContent.kind, state: state), documents: documents)
        )
    }

    func type(_ text: String, into content: DocumentContent) {
        let storage = content.document.source.storage
        storage.replaceCharacters(in: NSRange(location: storage.length, length: 0), with: text)
    }

    @Test func `the tab is the file's name with a document picture, and says when the text has edits`() throws {
        let path = try file("notes.md", "# Notes\n")
        let pane = try content(path)
        #expect(pane.title == "notes.md" && pane.glyph == .symbol("doc.text") && pane.detail == root)
        #expect(!pane.isEdited && pane.closeWarning == nil)
        type("more\n", into: pane)
        #expect(pane.isEdited && pane.closeWarning != nil)
        pane.save()
        #expect(!pane.isEdited && pane.closeWarning == nil && pane.failure == nil)
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "# Notes\nmore\n")
        pane.stop()
    }

    @Test func `it comes back as it was: the file and which view`() throws {
        let path = try file("a.md", "# A\n")
        let pane = try content(path)
        #expect(pane.descriptor.kind == "document" && pane.descriptor.state["file"] == path)
        #expect(pane.mode == .rendered && pane.descriptor.state["view"] == "rendered")
        #expect(pane.descriptor.state["title"] == "a.md", "a tab that is not running shows the name")
        var saves = 0
        pane.onChange = { saves += 1 }
        pane.toggleMode()
        #expect(pane.mode == .source && saves == 1)
        let back = try #require(DocumentContent(pane.descriptor, documents: documents))
        #expect(back.mode == .source && back.document === pane.document)
        #expect(
            DocumentContent(PaneDescriptor(kind: "document", state: ["view": "source"]), documents: documents) == nil
        )
        pane.stop()
        back.stop()
    }

    @Test func `Markdown and a diagram open rendered and can be toggled; any other text is source only`() throws {
        let diagram = try content(try file("d.mmd", "flowchart LR\n  A --> B\n"))
        #expect(diagram.mode == .rendered && diagram.canRender)
        let text = try content(try file("build.log", "# not a heading\n"), mode: "rendered")
        #expect(text.mode == .source && !text.canRender)
        text.toggleMode()
        #expect(text.mode == .source)
        diagram.stop()
        text.stop()
    }

    @Test func `two panes on one file are one document, and its edits are at stake only when the last one closes`()
        throws
    {
        let path = try file("shared.md", "one\n")
        let first = try content(path)
        let second = try content(root + "/./shared.md")
        #expect(first.document === second.document)
        type("two\n", into: first)
        #expect(second.isEdited && first.closeWarning == nil && second.closeWarning == nil, "the other pane keeps it")
        first.stop()
        #expect(second.closeWarning != nil && documents.all.count == 1)
        second.stop()
        #expect(documents.all.isEmpty)
    }

    @Test func `saving where nothing can be written says so and keeps the edits`() throws {
        let folder = root + "/locked"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        try "old\n".write(toFile: folder + "/a.md", atomically: true, encoding: .utf8)
        let pane = try content(folder + "/a.md")
        type("new\n", into: pane)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder) }
        pane.save()
        #expect(pane.failure == "Not saved: Permission denied." && pane.isEdited)
        #expect(try String(contentsOfFile: folder + "/a.md", encoding: .utf8) == "old\n")
        pane.failure = nil
        pane.stop()
    }
}
