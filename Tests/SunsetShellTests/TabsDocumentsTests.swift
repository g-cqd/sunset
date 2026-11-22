import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The documents of the store as tabs: a document opens as a tab like any other, among the tabs; one that is open is shown where it is; a
/// deleted one closes.
@MainActor @Suite("Documents as tabs") struct TabsDocumentsTests {
    let harness = TabsHarness()
    var tabs: TabsModel {
        harness.tabs
    }
    let notes = UUID()
    let plan = UUID()

    /// The tabs that show `document`, among the window's tabs.
    func tabsShowing(_ document: UUID) -> [Workspace.Item] {
        tabs.workspace.items.filter { item in item.panes.contains { tabs.document(in: $0) == document } }
    }

    @Test func `a document opens as a tab like any other: after the one shown, among the tabs`() throws {
        tabs.newTab()
        tabs.newTab()
        tabs.select(index: 0)
        tabs.show(document: notes)
        #expect(tabs.workspace.count == 3 && tabs.workspace.selectedIndex == 1, "where a new tab goes")
        #expect(harness.made.last?.descriptor == .document(stored: notes))
        #expect(tabs.document(in: tabs.workspace.items[1].focused) == notes)

        tabs.select(index: 2)
        tabs.show(document: notes)
        #expect(tabs.workspace.count == 3 && tabs.workspace.selectedIndex == 1, "shown where it is, not opened twice")
    }

    @Test func `a document beside another pane is found there, and takes the keyboard`() throws {
        tabs.newTab()
        tabs.show(document: notes)
        tabs.newSplit(.right)
        tabs.newTab()
        #expect(tabs.workspace.selectedIndex == 2)
        tabs.show(document: notes)
        #expect(tabs.workspace.count == 3 && tabs.workspace.selectedIndex == 1, "no second tab on it")
        #expect(tabs.shownPane.flatMap(tabs.document(in:)) == notes, "the document's pane, not the one beside it")
    }

    @Test func `a second tab on a document is asked for by name, and both show it`() throws {
        tabs.newTab()
        tabs.show(document: plan)
        tabs.openTab(document: plan, at: 0, show: false)
        #expect(tabsShowing(plan).count == 2 && tabs.workspace.selectedIndex == 2, "not shown: the selection stays")
    }

    @Test func `a new document is made by the shelf and opened as a tab; with no shelf nothing happens`() throws {
        tabs.newDocument()
        #expect(tabs.workspace.isEmpty)
        tabs.shelf.create = { [notes] in notes }
        tabs.newTab()
        tabs.newDocument()
        #expect(tabsShowing(notes).count == 1 && tabs.workspace.selectedIndex == 1)
    }

    @Test func `deleting a document closes its panes here, then the shelf deletes it`() throws {
        var deleted: [UUID] = []
        tabs.shelf.delete = {
            deleted.append($0)
            return $0 != self.plan
        }
        tabs.newTab()
        tabs.show(document: notes)
        tabs.openTab(document: notes, at: 0, show: false)
        tabs.show(document: plan)
        tabs.delete(document: notes)
        #expect(deleted == [notes] && tabs.workspace.count == 2 && tabsShowing(plan).count == 1)
        #expect(tabs.workspace.allPanes.allSatisfy { tabs.document(in: $0) != notes })
        tabs.delete(document: plan)
        #expect(tabsShowing(plan).count == 1, "one that could not be deleted keeps its pane")
    }

    @Test func `a document that is open and dragged is opened again where it is dropped, as from any list`() throws {
        tabs.newTab()
        let first = tabs.workspace.items[0].id
        tabs.show(document: notes)
        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.dropDragged(onto: first, action: .moveBefore))
        #expect(tabs.workspace.count == 3 && tabsShowing(notes).count == 2)
        #expect(tabs.document(in: tabs.workspace.items[0].focused) == notes)
    }
}
