import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// A document's row dragged (the owner, 2026-11-15): onto the tab list it opens as a tab there, onto a pane it splits it, into
/// the Favorites it is kept there. The document stays in Documents in each case.
@MainActor @Suite("A document dragged") struct TabsDocumentsDragTests {
    let harness = TabsHarness()
    var tabs: TabsModel { harness.tabs }
    let notes = UUID()

    @Test func `onto the tab list it opens as a tab at that place, among the tabs`() throws {
        tabs.newTab()
        tabs.newTab()
        let second = tabs.workspace.items[1].id
        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.canDrop(onto: second, action: .moveBefore))
        #expect(tabs.dropDragged(onto: second, action: .moveBefore))
        #expect(tabs.workspace.count == 3 && tabs.document(in: tabs.workspace.items[1].focused) == notes)
        #expect(tabs.workspace.items[2].id == second && tabs.dragged == nil)
    }

    @Test func `onto the middle of a tab's row, or onto a pane, it splits it`() throws {
        tabs.newTab()
        let item = tabs.workspace.items[0]
        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.canDrop(onto: item.focused) && tabs.dropDragged(onto: item.focused, edge: .right))
        let split = try #require(tabs.workspace.items.first)
        #expect(tabs.workspace.count == 1 && split.panes.count == 2)
        #expect(split.panes.contains { tabs.document(in: $0) == notes })

        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.dropDragged(onto: split.id, action: .split(.left)))
        #expect(tabs.workspace.count == 1 && tabs.workspace.items[0].panes.count == 3)
    }

    @Test func `into the Favorites it is kept there, on the line and beside an entry`() throws {
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.canDropOnFavoritesLine && tabs.dropDraggedOnFavoritesLine())
        #expect(tabs.favorites.favorites.entries.count == 2 && tabs.workspace.count == 1)

        _ = tabs.itemProvider(for: .document(notes))
        #expect(tabs.canDrop(onEntry: kept) && tabs.dropDragged(onEntry: kept, after: false))
        let entries = tabs.favorites.favorites.entries
        #expect(entries.count == 3 && entries[1].id == kept)
        let first = try #require(entries.first?.open?.focused)
        #expect(tabs.document(in: first) == notes)
    }

    @Test func `a drop that is refused opens nothing`() throws {
        tabs.newTab()
        tabs.dragged = nil
        #expect(!tabs.dropDragged(onto: tabs.workspace.items[0].id, action: .moveAfter) && tabs.workspace.count == 1)
    }
}

/// A document's tab, at the next start.
extension TabsDocumentsDragTests {
    @Test func `a document's tab comes back with the window, where it was among the tabs`() throws {
        tabs.newTab()
        tabs.show(document: notes)
        tabs.newTab()
        let saved = tabs.savedWindow()
        let again = TabsHarness()
        again.tabs.restore(try JSONDecoder().decode(SavedWindow.self, from: try JSONEncoder().encode(saved)))
        #expect(again.tabs.workspace.count == 3)
        #expect(again.tabs.document(in: again.tabs.workspace.items[1].focused) == notes)
    }
}
