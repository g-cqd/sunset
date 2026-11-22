import Foundation
import SunsetDocuments
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// What quitting would lose of the documents. Closing a pane loses nothing while another shows the document; quitting
/// closes them all, and names the edits no pane shows any more as well.
extension DocumentContentTests {
    @Test func `quitting names each edited document once, however many panes show it`() throws {
        let shared = try file("shared.md", "one\n")
        let first = try content(shared)
        let second = try content(shared, mode: "source")
        let other = try content(try file("other.md", "kept\n"))
        let ids = [PaneID(), PaneID(), PaneID()]
        let panes: [(PaneID?, any PaneContent)] = [(ids[0], first), (ids[1], second), (ids[2], other)]
        #expect(DocumentContent.quitLosses(of: documents, in: panes).isEmpty, "nothing is edited")

        type("two\n", into: second)
        let losses = DocumentContent.quitLosses(of: documents, in: panes)
        #expect(losses.map(\.text) == ["shared.md has edits that are not saved."])
        #expect(losses.first?.kind == .document && losses.first?.pane == ids[0], "a click on it shows a pane of it")
    }

    @Test func `quitting names the edits no pane shows any more, and where their file is`() throws {
        let path = try file("left.md", "one\n")
        let pane = try content(path)
        type("two\n", into: pane)
        pane.stop()
        let losses = DocumentContent.quitLosses(of: documents, in: [])
        #expect(losses.map(\.text) == ["left.md has edits that are not saved."] && losses.first?.pane == nil)
        #expect(losses.first?.file == path, "a click on it opens the file, with the edits")
    }

    @Test func `the answers of the sheet: Save writes and says whether it did, Don't Save forgets the edits`() throws {
        let path = try file("a.md", "one\n")
        let pane = try content(path)
        type("two\n", into: pane)
        #expect(pane.unsaved?.save() == true && !pane.isEdited)
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "one\ntwo\n")

        type("three\n", into: pane)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: root)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: root) }
        #expect(pane.unsaved?.save() == false && pane.isEdited && pane.failure != nil, "it is said in the pane")
        pane.unsaved?.discard()
        pane.stop()
        #expect(documents.all.isEmpty, "given up, the edits go with the pane")
    }

    @Test func `a pane that loses the keyboard saves its file when the setting says so, and not otherwise`() throws {
        let path = try file("a.md", "one\n")
        let pane = try content(path)
        pane.setState(focused: true, visible: true)
        type("two\n", into: pane)
        pane.setState(focused: false, visible: true)
        #expect(pane.isEdited, "off by default")
        documents.autosave.onFocusLoss = true
        pane.setState(focused: true, visible: true)
        pane.setState(focused: false, visible: true)
        #expect(!pane.isEdited)
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "one\ntwo\n")
    }

    @Test func `a document of the store that cannot be kept is asked about like a file`() throws {
        let state = ["document": UUID().uuidString]
        let pane = try #require(
            DocumentContent(PaneDescriptor(kind: DocumentContent.kind, state: state), documents: documents)
        )
        type("text\n", into: pane)
        #expect(pane.document.isStored && !pane.document.keepsItself, "no store here: it cannot be kept")
        #expect(pane.isEdited && pane.unsaved?.title == pane.title)
    }
}
