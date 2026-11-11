import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("Dragging across the Favorites line") struct TabsFavoritesDragTests {
    /// A window with `tabs` tabs whose first `kept` were kept, in order; the entries' ids.
    private func window(tabs count: Int, kept: Int) throws -> (harness: TabsHarness, entries: [Favorites.NodeID]) {
        let harness = TabsHarness()
        for _ in 0 ..< count { harness.tabs.newTab() }
        var entries: [Favorites.NodeID] = []
        for _ in 0 ..< kept {
            harness.tabs.keep(item: harness.tabs.workspace.items[0].id)
            entries.append(try #require(harness.tabs.workspace.selectedEntry))
        }
        return (harness, entries)
    }

    private func order(_ harness: TabsHarness) -> [Favorites.NodeID] {
        harness.tabs.favorites.favorites.entries.map(\.id)
    }

    @Test func `a tab dropped on the line is kept at the end, still running`() throws {
        let (harness, entries) = try window(tabs: 3, kept: 1)
        let tab = harness.tabs.workspace.items[0]
        let content = try #require(harness.content(tab.focused))
        _ = harness.tabs.itemProvider(for: .item(tab.id))
        #expect(harness.tabs.canDropOnFavoritesLine && harness.tabs.dropDraggedOnFavoritesLine())
        #expect(order(harness).count == 2 && order(harness).first == entries[0] && !content.stopped)
        #expect(harness.tabs.workspace.count == 1 && harness.tabs.dragged == nil)
    }

    @Test func `a tab dropped on an entry's row is kept before or after it`() throws {
        let (harness, entries) = try window(tabs: 4, kept: 2)
        let first = harness.tabs.workspace.items[0].id
        _ = harness.tabs.itemProvider(for: .item(first))
        harness.tabs.dropDragged(onEntry: entries[1], after: false)
        let before = order(harness)
        #expect(before.count == 3 && before[0] == entries[0] && before[2] == entries[1])
        _ = harness.tabs.itemProvider(for: .item(harness.tabs.workspace.items[0].id))
        harness.tabs.dropDragged(onEntry: entries[0], after: true)
        #expect(order(harness)[0] == entries[0] && order(harness).count == 4 && order(harness)[2] == before[1])
    }

    @Test func `an entry dragged onto another entry moves before or after it, either way`() throws {
        let (harness, entries) = try window(tabs: 3, kept: 3)
        _ = harness.tabs.itemProvider(for: .entry(entries[0]))
        harness.tabs.dropDragged(onEntry: entries[2], after: true)
        #expect(order(harness) == [entries[1], entries[2], entries[0]])
        _ = harness.tabs.itemProvider(for: .entry(entries[0]))
        harness.tabs.dropDragged(onEntry: entries[1], after: false)
        #expect(order(harness) == [entries[0], entries[1], entries[2]])
        _ = harness.tabs.itemProvider(for: .entry(entries[1]))
        harness.tabs.dropDragged(onEntry: entries[2], after: false)
        #expect(order(harness) == [entries[0], entries[1], entries[2]], "dropped where it already is")
        _ = harness.tabs.itemProvider(for: .entry(entries[1]))
        #expect(!harness.tabs.canDrop(onEntry: entries[1]))
    }

    @Test func `an entry dropped among the tabs leaves the Favorites as a tab at that place`() throws {
        let (harness, entries) = try window(tabs: 3, kept: 1)
        let tabs = harness.tabs.workspace.items.map(\.id)
        _ = harness.tabs.itemProvider(for: .entry(entries[0]))
        #expect(
            harness.tabs.canDrop(onto: tabs[1], action: .moveAfter)
                && !harness.tabs.canDrop(onto: tabs[1], action: .split(.left))
        )
        harness.tabs.dropDragged(onto: tabs[1], action: .moveAfter)
        #expect(harness.tabs.favorites.isEmpty && harness.tabs.workspace.count == 3)
        #expect(harness.tabs.workspace.items.map(\.id)[0 ... 1] == [tabs[0], tabs[1]][...])
        #expect(harness.tabs.workspace.selectedIndex == 2)
    }

    @Test func `a pane or nothing cannot be dropped on the Favorites`() throws {
        let (harness, entries) = try window(tabs: 2, kept: 1)
        _ = harness.tabs.itemProvider(for: .pane(harness.tabs.workspace.items[0].focused))
        #expect(!harness.tabs.canDrop(onEntry: entries[0]) && !harness.tabs.canDropOnFavoritesLine)
        #expect(!harness.tabs.dropDragged(onEntry: entries[0], after: true))
        harness.tabs.dragged = nil
        #expect(!harness.tabs.dropDraggedOnFavoritesLine())
    }
}
