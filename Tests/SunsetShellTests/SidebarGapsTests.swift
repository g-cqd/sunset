import SunsetPane
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0038 B, F): the places to drop are the gaps between rows, the top and the bottom of the
/// Favorites included; "dragging tabs don't show the position placeholder at the top of favorites or the bottom of favorites
/// which also prevents folders to be moved in such places". Gap k is before the k-th row shown; the last is after them all.
@MainActor
@Suite("The gaps between the sidebar's rows")
struct SidebarGapsTests {
    @Test func `a folder is moved to the top of the Favorites, before a folder, and to their bottom, out of a folder`()
        throws
    {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newFolder()
        tabs.renamingRow = nil
        let first = try #require(tabs.favorites.favorites.nodes.last?.id)
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: tab, show: false))
        tabs.newFolder()
        tabs.renamingRow = nil
        let second = try #require(tabs.favorites.favorites.nodes.last?.id)
        #expect(tabs.favorites.favorites.nodes.map(\.id) == [first, entry, second])

        _ = tabs.itemProvider(for: .entry(second))
        let top = tabs.favoritesGap(0)
        #expect(top == .favorites(in: nil, at: 0) && tabs.canDropDragged(in: top))
        #expect(tabs.dropDragged(in: top))
        #expect(tabs.favorites.favorites.nodes.map(\.id) == [second, first, entry])

        _ = tabs.itemProvider(for: .entry(second))
        let bottom = tabs.favoritesGap(tabs.favoritesRows.count)
        #expect(bottom == .favorites(in: nil, at: nil))
        #expect(tabs.dropDragged(in: bottom))
        #expect(tabs.favorites.favorites.nodes.map(\.id) == [first, entry, second])
    }

    @Test func `a gap inside an open folder puts it in that folder, at that place`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newFolder()
        tabs.renamingRow = nil
        let folder = try #require(tabs.favorites.favorites.nodes.last?.id)
        for _ in 0 ..< 2 {
            tabs.newTab()
            let made = try #require(tabs.workspace.selectedID)
            let entry = try #require(tabs.keep(item: made, show: false))
            tabs.favorites.edit { $0.move([entry], into: folder, at: Int.max) }
        }
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let rows = tabs.favoritesRows
        #expect(rows.count == 3, "the folder and its two entries")
        #expect(tabs.favoritesGap(2) == .favorites(in: folder, at: 1))
        _ = tabs.itemProvider(for: .item(tab))
        #expect(tabs.dropDragged(in: tabs.favoritesGap(2)))
        #expect(tabs.favorites.favorites.location(of: rows[2])?.index == 2)
    }

    @Test func `Today's gaps are its places`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        for _ in 0 ..< 3 { tabs.newTab() }
        let ids = tabs.workspace.items.map(\.id)
        _ = tabs.itemProvider(for: .item(ids[0]))
        #expect(tabs.dropDragged(in: .today(at: 2)))
        #expect(tabs.workspace.items.map(\.id) == [ids[1], ids[0], ids[2]])
    }
}
