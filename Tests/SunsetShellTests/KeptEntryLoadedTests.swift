import Foundation
import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// A kept page open but not made yet; its tile was drawn as loaded, and its
/// preview said "Terminal" with a folder for a picture.
@MainActor @Suite("A kept entry back from the session, not made yet")
struct KeptEntryLoadedTests {
    @Test func `it is not drawn as loaded, and its preview reads its saved page until it is made`() throws {
        var kept = Favorites()
        let pane = PaneID()
        let added = kept.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane))
        let id = try #require(added)
        kept.open(id)
        let page = PaneDescriptor(kind: "web", state: ["url": "https://claude.ai/", "title": "Claude"])
        let favorites = FavoritesModel()
        favorites.restore(SavedFavorites(favorites: kept, contents: [pane: page]))
        // An entry opened but not made yet (a window selected it, the page loads when it is shown): not what a launch gives.
        favorites.edit { $0.open(id) }
        favorites.pending[pane] = page
        let harness = TabsHarness(favorites: favorites)
        let entry = try #require(harness.tabs.favorites.favorites.entry(id))
        #expect(entry.isOpen && harness.tabs.content(pane) == nil)
        #expect(!harness.tabs.isLoaded(entry: entry), "open, but nothing runs yet")
        #expect(harness.tabs.pendingDescriptor(pane) == page, "what its preview names and pictures")
        harness.tabs.select(entry: id)
        let shown = try #require(harness.tabs.favorites.favorites.entry(id))
        #expect(harness.tabs.isLoaded(entry: shown) && harness.tabs.pendingDescriptor(pane) == nil)
    }
}
