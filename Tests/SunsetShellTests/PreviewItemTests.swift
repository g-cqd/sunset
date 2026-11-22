import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "there's no preview on loaded favorites tabs or pinned tabs". The hover card shows what is under the pointer: a tab
/// of Today, or an open kept entry (a favourite, a tile); an entry not loaded has nothing to show.
@MainActor
@Suite("What the hover card shows")
struct PreviewItemTests {
    @Test func `a tab, an open favourite and an open tile are found by the id hovered; an unloaded entry is not`()
        throws
    {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = FavoritesModel()
        tabs.newTab()
        let today = try #require(tabs.workspace.selectedItem)
        #expect(tabs.previewItem(today.id)?.id == today.id)

        tabs.newTab()
        let kept = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: kept, show: false))
        let open = try #require(tabs.favorites.favorites.entry(entry)?.open)
        #expect(tabs.hoverID(entry: entry) == open.id)
        #expect(tabs.previewItem(open.id)?.panes == open.panes, "an open favourite")

        tabs.newTab()
        let pinnedTab = try #require(tabs.workspace.selectedID)
        let tile = try #require(tabs.pin(item: pinnedTab, show: false))
        let tileOpen = try #require(tabs.pinned?.favorites.entry(tile)?.open)
        #expect(tabs.hoverID(entry: tile) == tileOpen.id)
        #expect(tabs.previewItem(tileOpen.id)?.panes == tileOpen.panes, "an open tile")

        tabs.unload(entry: entry)
        #expect(tabs.hoverID(entry: entry) == nil, "not loaded: nothing to show")
        #expect(tabs.previewItem(open.id) == nil)
    }
}
