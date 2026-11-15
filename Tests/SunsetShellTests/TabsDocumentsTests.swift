import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// The documents of the sidebar as tabs (roadmap 0030 step ST-5, 0031): a document's row under the Documents heading is its
/// tab while it is open; a document of a section opens where it already is; a deleted one closes.
@MainActor @Suite("Documents as tabs") struct TabsDocumentsTests {
    let harness = TabsHarness()
    var tabs: TabsModel { harness.tabs }
    let notes = UUID()
    let plan = UUID()

    @Test func `a click on a document's row opens it in place: its tab is on the row, not among the tabs`() throws {
        tabs.newTab()
        tabs.open(document: notes)
        let item = try #require(tabs.shelved(notes))
        #expect(tabs.isSelected(item.id) && tabs.document(in: item.focused) == notes)
        #expect(harness.made.last?.descriptor == .document(stored: notes))
        #expect(tabs.listedItems(shelf: true).map(\.id) == [tabs.workspace.items[0].id])
        #expect(tabs.listedItems(shelf: false).count == 2, "with the heading hidden it is a tab like any other")

        tabs.select(index: 0)
        tabs.open(document: notes)
        #expect(
            tabs.workspace.count == 2 && tabs.isSelected(item.id),
            "a second click shows it, it is not opened twice"
        )
    }

    @Test func `the minus unloads it: the pane closes, the document stays`() throws {
        tabs.newTab()
        tabs.open(document: notes)
        let content = try #require(harness.made.last)
        tabs.unload(document: notes)
        #expect(content.stopped && tabs.shelved(notes) == nil && tabs.workspace.count == 1)
    }

    @Test func `a document of a section is shown where it already is in the window, else in a new tab on its row`()
        throws
    {
        tabs.newTab()
        tabs.openTab(document: plan, at: 1, show: false)
        #expect(tabs.shelved(plan) == nil && tabs.listedItems(shelf: true).count == 2, "a tab among the tabs")
        tabs.show(document: plan)
        #expect(tabs.workspace.count == 2 && tabs.workspace.selectedIndex == 1)
        tabs.show(document: notes)
        #expect(tabs.workspace.count == 3 && tabs.shelved(notes) != nil)
    }

    @Test func `a tab on a row that no longer shows its document is among the tabs again`() throws {
        tabs.newTab()
        tabs.open(document: notes)
        let item = try #require(tabs.shelved(notes))
        let content = try #require(harness.made.last)
        content.descriptor = .terminal(directory: nil)
        #expect(tabs.shelved(notes) == nil && tabs.listedItems(shelf: true).contains { $0.id == item.id })
    }

    @Test func `a new document is made by the shelf and opened in place; with no shelf nothing happens`() throws {
        tabs.newDocument()
        #expect(tabs.workspace.isEmpty)
        tabs.shelf.create = { [notes] in notes }
        tabs.newDocument()
        #expect(tabs.shelved(notes) != nil)
    }

    @Test func `deleting a document closes its panes here, then the shelf deletes it`() throws {
        var deleted: [UUID] = []
        tabs.shelf.delete = { deleted.append($0) }
        tabs.newTab()
        tabs.open(document: notes)
        tabs.openTab(document: notes, at: 0, show: false)
        tabs.open(document: plan)
        tabs.delete(document: notes)
        #expect(deleted == [notes] && tabs.workspace.count == 2 && tabs.shelved(plan) != nil)
        #expect(tabs.workspace.allPanes.allSatisfy { tabs.document(in: $0) != notes })
    }
}
