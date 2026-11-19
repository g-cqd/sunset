import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// 0035's "not done" (roadmap 0036 F): a tab dragged from one window is dropped in another. The drag is the window's it
/// started in; the window it is dropped in takes it: a tab of another Space comes to its Space (the first window stays where
/// it is), a kept entry of the same profile is the same entry.
@MainActor
@Suite("Dragging from one window to another", .serialized)
struct TabsCrossWindowDragTests {
    @Test func `a tab of the same Space is put in order in the other window, and pinned from it`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        first.newTab()
        first.newTab()
        let tabs = first.workspace.items.map(\.id)
        let second = harness.window()
        _ = first.itemProvider(for: .item(tabs[2]))
        #expect(second.canDropDragged(in: .today(at: 0)))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(second.workspace.items.map(\.id) == [tabs[2], tabs[0], tabs[1]])
        #expect(first.dragged == nil && second.dragged == nil)
    }

    @Test func `a tab of another Space comes to the Space of the window it is dropped in; the first window stays`()
        throws
    {
        let one = SpaceHarness()
        let two = SpaceHarness()
        let first = one.window()
        first.newTab()
        first.newTab()
        let tab = try #require(first.workspace.items.last?.id)
        let second = two.window()
        second.newTab()
        let there = try #require(second.workspace.items.first?.id)
        _ = first.itemProvider(for: .item(tab))
        #expect(second.canDrop(onto: there, action: .moveBefore))
        #expect(second.dropDragged(onto: there, action: .moveBefore))
        #expect(second.workspace.items.map(\.id) == [tab, there])
        #expect(!first.workspace.items.contains { $0.id == tab } && first.space === one.space)
        #expect(two.content(second.workspace.items[0].focused) != nil, "its content came with it, running")
    }

    @Test func `a favourite dragged from one window becomes a tab in another of the same profile`() throws {
        let favorites = FavoritesModel()
        let one = SpaceHarness(favorites: favorites)
        let two = SpaceHarness(favorites: favorites)
        let first = one.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let entry = try #require(first.keep(item: tab, show: false))
        let second = two.window()
        _ = first.itemProvider(for: .entry(entry))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(second.workspace.count == 1 && favorites.favorites.entries.isEmpty)
    }
}
