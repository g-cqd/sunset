import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "Moving a tab to the favorites makes it lose its keep awake status". What is kept awake is the tab, wherever it
/// goes: Today, the Favorites, the grid, another window.
@MainActor
@Suite("Keeping the Mac awake through moves")
struct KeepAwakeMovesTests {
    @Test func `a tab kept awake stays so kept in the Favorites, pinned, and back among Today's tabs`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = FavoritesModel()
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        tabs.keepAwake(item: tab, until: .closed)
        let entry = try #require(tabs.keep(item: tab, show: false))
        #expect(tabs.keepsAwake(entry: entry) == .closed && tabs.keepsMacAwake, "kept in the Favorites")
        #expect(tabs.pin(entry: entry))
        #expect(tabs.keepsAwake(entry: entry) == .closed && tabs.keepsMacAwake, "pinned")
        let back = try #require(tabs.release(entry: entry))
        #expect(tabs.keepsAwake(item: back) == .closed && tabs.keepsMacAwake, "a tab again")
    }

    @Test func `a favourite kept awake stays so as a tab again`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: tab))
        tabs.keepAwake(entry: entry, until: .closed)
        let back = try #require(tabs.release(entry: entry))
        #expect(tabs.keepsAwake(item: back) == .closed)
    }

    @Test func `a tab kept awake stays so in another window of the Space, and in another Space`() throws {
        let one = SpaceHarness()
        let two = SpaceHarness()
        let first = one.window()
        first.newTab()
        first.newTab()
        let tab = try #require(first.workspace.items.last?.id)
        first.keepAwake(item: tab, until: .closed)
        let second = two.window()
        _ = first.itemProvider(for: .item(tab))
        #expect(second.dropDragged(in: .today(at: 0)))
        #expect(second.keepsAwake(item: tab) == .closed && second.keepsMacAwake && !first.keepsMacAwake)
    }
}
