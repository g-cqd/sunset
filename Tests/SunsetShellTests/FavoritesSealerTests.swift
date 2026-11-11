import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("The command sealer is made only when needed") struct FavoritesSealerTests {
    @Test
    func `no sealer is made at launch or for entries without a command; it is made once when a command is checked`()
        throws
    {
        let favorites = FavoritesModel()
        var made = 0
        favorites.makeSealer = {
            made += 1
            return TestSealer()
        }
        let harness = TabsHarness(favorites: favorites)
        harness.tabs.newTab()
        harness.tabs.newTab()
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let entry = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: entry)
        harness.tabs.select(entry: entry)
        #expect(made == 0)
        harness.tabs.favorites.setCommand("make", for: entry)
        _ = harness.tabs.favorites.isTrusted(entry)
        #expect(made == 1)
    }
}
