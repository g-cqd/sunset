import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("Several rows selected together") struct TabsSelectionTests {
    /// A window with `count` tabs, the first shown; the tabs' rows. (`select(index:)` counts open entries first, as Cmd-1 does: `select(item:)` here.)
    private func window(_ count: Int) -> (harness: TabsHarness, tabs: [RowTarget]) {
        let harness = TabsHarness()
        for _ in 0 ..< count { harness.tabs.newTab() }
        harness.tabs.select(index: 0)
        return (harness, harness.tabs.workspace.items.map { .tab($0.id) })
    }

    @Test func `Cmd-click adds the shown row and the clicked one, and toggles; nothing new is shown`() {
        let (harness, rows) = window(4)
        #expect(harness.tabs.click(rows[2], command: true, shift: false))
        #expect(harness.tabs.marked == [rows[0], rows[2]] && harness.tabs.workspace.selectedIndex == 0)
        harness.tabs.click(rows[3], command: true, shift: false)
        harness.tabs.click(rows[2], command: true, shift: false)
        #expect(harness.tabs.marked == [rows[0], rows[3]])
    }

    @Test func `Shift-click takes the range from the last row clicked, in either direction`() {
        let (harness, rows) = window(5)
        harness.tabs.click(rows[1], command: true, shift: false)
        harness.tabs.click(rows[3], command: false, shift: true)
        #expect(harness.tabs.marked == Array(rows[1 ... 3]))
        harness.tabs.click(rows[0], command: false, shift: true)
        #expect(harness.tabs.marked == Array(rows[0 ... 1]))
    }

    @Test func `a plain click clears the selection and lets the row be shown`() {
        let (harness, rows) = window(3)
        harness.tabs.click(rows[1], command: true, shift: false)
        #expect(!harness.tabs.click(rows[2], command: false, shift: false) && harness.tabs.marked.isEmpty)
    }

    @Test func `a selection of tabs and entries is grouped in a new folder, in its order, everything still running`()
        throws
    {
        let (harness, rows) = window(4)
        harness.tabs.keep(item: harness.tabs.workspace.items[3].id)
        let entry = try #require(harness.tabs.workspace.selectedEntry)
        let contents = harness.made
        harness.tabs.select(item: harness.tabs.workspace.items[0].id)
        harness.tabs.click(rows[1], command: true, shift: false)
        harness.tabs.click(.node(entry), command: true, shift: false)
        let selection = harness.tabs.marked
        #expect(selection.first == .node(entry), "the Favorites come first in the sidebar")
        harness.tabs.group(selection)
        guard case .folder(let folder)? = harness.tabs.favorites.favorites.nodes.last else {
            Issue.record("no folder")
            return
        }
        #expect(folder.children.count == 3 && folder.children.first?.id == entry)
        #expect(harness.tabs.workspace.count == 1 && contents.allSatisfy { !$0.stopped })
        #expect(harness.tabs.marked.isEmpty && harness.tabs.renamingRow == .node(folder.id))
    }

    @Test func `adding to and removing from the Favorites works on every row of the selection`() {
        let (harness, rows) = window(3)
        harness.tabs.addToFavorites(Array(rows[1 ... 2]))
        #expect(harness.tabs.favorites.favorites.entries.count == 2 && harness.tabs.workspace.count == 1)
        #expect(harness.tabs.workspace.selectedEntry == nil, "the shown tab stays shown")
        let entries = harness.tabs.favorites.favorites.entries.map { RowTarget.node($0.id) }
        harness.tabs.removeFromFavorites(entries)
        #expect(harness.tabs.favorites.isEmpty && harness.tabs.workspace.count == 3)
    }

    @Test func `deleting a selection asks once when something runs, then deletes it all`() throws {
        let (harness, rows) = window(3)
        harness.tabs.addToFavorites(Array(rows[1 ... 2]))
        let entries = harness.tabs.favorites.favorites.entries.map { RowTarget.node($0.id) }
        try #require(harness.made.last).closeWarning = "make is running"
        harness.tabs.delete(entries)
        #expect(harness.tabs.favorites.favorites.entries.count == 2)
        harness.tabs.delete(entries)
        #expect(harness.tabs.favorites.isEmpty && harness.made.last?.stopped == true)
    }

    @Test func `dragging a selected row carries the selection into a folder or onto the line`() throws {
        let (harness, rows) = window(4)
        harness.tabs.newFolder()
        let folder = try #require(harness.tabs.favorites.favorites.nodes.first?.id)
        harness.tabs.click(rows[1], command: true, shift: false)
        harness.tabs.click(rows[2], command: true, shift: false)
        guard case .tab(let dragged) = rows[2] else { return }
        _ = harness.tabs.itemProvider(for: .item(dragged))
        #expect(harness.tabs.dropDragged(intoFolder: folder))
        guard case .folder(let filled)? = harness.tabs.favorites.favorites.node(folder) else { return }
        #expect(filled.children.count == 3 && harness.tabs.workspace.count == 1 && harness.tabs.marked.isEmpty)
    }

    @Test func `dragging a selection of entries among the tabs gives them back as tabs there, in order`() throws {
        let (harness, rows) = window(4)
        harness.tabs.addToFavorites(Array(rows[2 ... 3]))
        let entries = harness.tabs.favorites.favorites.entries.map(\.id)
        harness.tabs.select(entry: entries[0])
        harness.tabs.click(.node(entries[1]), command: true, shift: false)
        _ = harness.tabs.itemProvider(for: .entry(entries[1]))
        let first = harness.tabs.workspace.items[0].id
        #expect(harness.tabs.dropDragged(onto: first, action: .moveAfter))
        #expect(harness.tabs.favorites.isEmpty && harness.tabs.workspace.count == 4)
        #expect(harness.tabs.workspace.items.map { RowTarget.tab($0.id) } == [rows[0], rows[2], rows[3], rows[1]])
    }

    @Test func `dragging selected tabs before a tab puts them there, in order`() {
        let (harness, rows) = window(5)
        harness.tabs.select(item: harness.tabs.workspace.items[3].id)
        harness.tabs.click(rows[4], command: true, shift: false)
        _ = harness.tabs.itemProvider(for: .item(harness.tabs.workspace.items[4].id))
        #expect(harness.tabs.dropDragged(onto: harness.tabs.workspace.items[1].id, action: .moveBefore))
        #expect(
            harness.tabs.workspace.items.map { RowTarget.tab($0.id) } == [rows[0], rows[3], rows[4], rows[1], rows[2]]
        )
    }

    @Test func `a drag of a row outside the selection carries that row alone`() {
        let (harness, rows) = window(3)
        harness.tabs.click(rows[1], command: true, shift: false)
        #expect(harness.tabs.dragRows(for: rows[2]) == [rows[2]])
        #expect(harness.tabs.dragRows(for: rows[1]) == [rows[0], rows[1]])
    }
}
