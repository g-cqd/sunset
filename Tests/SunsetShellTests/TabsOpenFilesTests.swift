import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Files opened in a window (R6, roadmap 0023 step M-f): from the Open panel, a drop, Finder, the command bar. Each in a
/// tab of its own; one this window already shows is shown, not opened twice.
@MainActor
@Suite("Opening files in a window")
struct TabsOpenFilesTests {
    private func bar(_ query: String) -> CommandBar {
        var bar = CommandBar(purpose: .search)
        bar.query = query
        return bar
    }

    @Test func `each file opens in a tab of its own, the last one shown`() {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.tabs.open(files: ["/tmp/a.md", "/tmp/b.txt"])
        #expect(harness.tabs.workspace.count == 3)
        #expect(harness.made.map(\.descriptor.documentFile) == [nil, "/tmp/a.md", "/tmp/b.txt"])
        #expect(harness.tabs.shownPane.flatMap(harness.content)?.descriptor.documentFile == "/tmp/b.txt")
    }

    @Test func `a file this window already shows is shown, however its path was written`() {
        let harness = TabsHarness()
        harness.tabs.open(files: ["/tmp/a.md"])
        harness.tabs.newTab()
        harness.tabs.open(files: ["/tmp/x/../a.md"])
        #expect(harness.tabs.workspace.count == 2 && harness.made.count == 2)
        #expect(harness.tabs.shownPane.flatMap(harness.content)?.descriptor.documentFile == "/tmp/a.md")
    }

    @Test func `the stored documents the bar offers: by title, for words only, and not the ones already in a tab`() {
        let harness = TabsHarness()
        let date = Date(timeIntervalSince1970: 0)
        let plan = ShelfDocument(id: UUID(), title: "Plan for the week", kind: .markdown, created: date, modified: date)
        let flow = ShelfDocument(id: UUID(), title: "Login flow", kind: .diagram, created: date, modified: date)
        harness.tabs.shelf.list = { [plan, flow] }
        harness.tabs.newTab()
        #expect(harness.tabs.barDocuments(bar("")).isEmpty, "nothing typed: the tabs only")
        #expect(harness.tabs.barDocuments(bar("week plan")).map(\.id) == [plan.id])
        #expect(harness.tabs.barDocuments(bar("l")).map(\.id) == [plan.id, flow.id])
        harness.tabs.show(document: plan.id)
        #expect(harness.tabs.barDocuments(bar("l")).map(\.id) == [flow.id])
    }

    /// Roadmap 0031, the owner's answers of 2026-11-16: the files opened lately are listed with the documents, and a
    /// private window lists neither, and is not remembered for what it opened.
    @Test func `a file opened is noted as opened lately, but not from a private window`() {
        let harness = TabsHarness()
        var noted: [String] = []
        harness.tabs.shelf.noteFile = { noted.append($0) }
        harness.tabs.open(files: ["/tmp/x/../a.md", "/tmp/b.txt"])
        #expect(noted == ["/tmp/a.md", "/tmp/b.txt"])
        harness.tabs.open(files: ["/tmp/a.md"])
        #expect(noted.count == 3, "shown again where it is: opened lately all the same")
        let hidden = TabsHarness()
        hidden.tabs.privateGroup = UUID()
        hidden.tabs.shelf.noteFile = { noted.append($0) }
        hidden.tabs.open(files: ["/tmp/c.md"])
        #expect(noted.count == 3 && hidden.tabs.workspace.count == 1)
    }

    @Test func `the documents a window lists: the store's and the files opened lately; none in a private window`() {
        let harness = TabsHarness()
        let date = Date(timeIntervalSince1970: 0)
        let plan = ShelfDocument(id: UUID(), title: "Plan", kind: .markdown, created: date, modified: date)
        let file = ShelfDocument(file: "/Users/me/notes/Tide tables.mmd", opened: Date(timeIntervalSince1970: 60))
        #expect(
            file.title == "Tide tables.mmd" && file.kind == .diagram && file.file == "/Users/me/notes/Tide tables.mmd"
        )
        #expect(file.modified == Date(timeIntervalSince1970: 60) && plan.file == nil)
        #expect(
            file.id == ShelfDocument(file: "/Users/me/notes/Tide tables.mmd", opened: date).id,
            "one row for one file"
        )
        #expect(ShelfDocument(file: "/a/b.md", opened: date).kind == .markdown)
        #expect(ShelfDocument(file: "/a/b.log", opened: date).kind == .text)
        harness.tabs.shelf.list = { [plan] }
        harness.tabs.shelf.files = { [file] }
        #expect(harness.tabs.listedDocuments.map(\.title) == ["Plan", "Tide tables.mmd"])
        harness.tabs.newTab()
        #expect(harness.tabs.barDocuments(bar("tide")).map(\.file) == ["/Users/me/notes/Tide tables.mmd"])
        harness.tabs.open(files: ["/Users/me/notes/Tide tables.mmd"])
        #expect(harness.tabs.barDocuments(bar("tide")).isEmpty, "it is a tab: the tab is listed")
        harness.tabs.privateGroup = UUID()
        #expect(harness.tabs.listedDocuments.isEmpty && harness.tabs.barDocuments(bar("plan")).isEmpty)
    }
}
