import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("A kept entry in several windows: one live view") struct TabsLiveEntryTests {
    /// Two windows on the same Favorites, the first with two tabs and its second tab kept and shown.
    private struct Pair {
        let first: TabsHarness
        let second: TabsHarness
        let entry: Favorites.NodeID
        let content: FakeContent
    }

    private func pair() throws -> Pair {
        let favorites = FavoritesModel()
        let first = TabsHarness(favorites: favorites)
        first.tabs.newTab()
        first.tabs.newTab()
        let second = TabsHarness(favorites: favorites)
        second.tabs.newTab()
        let content = try #require(first.content(first.tabs.workspace.items[1].focused))
        first.tabs.keep(item: first.tabs.workspace.items[1].id)
        let entry = try #require(first.tabs.workspace.selectedEntry)
        return Pair(first: first, second: second, entry: entry, content: content)
    }

    @Test func `the window that takes an entry draws it; the other keeps it selected and shows its picture`() throws {
        let pair = try pair()
        let (first, second, entry, content) = (pair.first, pair.second, pair.entry, pair.content)
        #expect(first.tabs.showsLive)
        second.tabs.select(entry: entry)
        #expect(second.tabs.showsLive && !first.tabs.showsLive)
        #expect(first.tabs.workspace.selectedEntry == entry, "still selected there, as a picture")
        #expect(content.visible && !content.stopped)
        first.tabs.takeShownEntry()
        #expect(first.tabs.showsLive && !second.tabs.showsLive)
    }

    @Test func `a window that leaves the live entry hands it to the other window that shows it`() throws {
        let pair = try pair()
        let (first, second, entry, content) = (pair.first, pair.second, pair.entry, pair.content)
        second.tabs.select(entry: entry)
        second.tabs.select(index: 1)
        #expect(second.tabs.workspace.selectedEntry == nil && first.tabs.showsLive)
        #expect(content.visible)
        first.tabs.select(item: first.tabs.workspace.items[0].id)
        #expect(!content.visible && !content.focused, "no window shows it: it is told it is hidden")
    }

    @Test func `selecting one of its own tabs tells the entry's content it is hidden`() throws {
        let pair = try pair()
        let (first, _, _, content) = (pair.first, pair.second, pair.entry, pair.content)
        #expect(content.visible && content.focused)
        first.tabs.select(item: first.tabs.workspace.items[0].id)
        #expect(!content.visible && !content.focused)
    }

    @Test func `a new tab while an entry is shown tells the entry's content it is hidden`() throws {
        let pair = try pair()
        let (first, _, _, content) = (pair.first, pair.second, pair.entry, pair.content)
        first.tabs.newTab()
        #expect(!content.visible && first.tabs.workspace.selectedEntry == nil)
    }

    @Test func `unloading the entry in one window leaves it in both`() throws {
        let pair = try pair()
        let (first, second, entry, content) = (pair.first, pair.second, pair.entry, pair.content)
        second.tabs.select(entry: entry)
        first.tabs.unload(entry: entry)
        #expect(
            content.stopped && first.tabs.workspace.selectedEntry == nil && second.tabs.workspace.selectedEntry == nil
        )
    }

    @Test func `an entry whose window went is live in no window until one takes it`() throws {
        let favorites = FavoritesModel()
        var gone: TabsHarness? = TabsHarness(favorites: favorites)
        gone?.tabs.newTab()
        let item = try #require(gone?.tabs.workspace.items[0].id)
        gone?.tabs.keep(item: item)
        let entry = try #require(gone?.tabs.workspace.selectedEntry)
        let other = TabsHarness(favorites: favorites)
        other.tabs.newTab()
        other.tabs.workspace.select(entry: entry)
        gone = nil
        #expect(!other.tabs.showsLive)
        other.tabs.takeShownEntry()
        #expect(other.tabs.showsLive)
    }
}
