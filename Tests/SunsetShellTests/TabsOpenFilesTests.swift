import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

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
}
