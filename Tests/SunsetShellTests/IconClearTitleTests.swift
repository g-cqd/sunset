import SunsetPane
import Testing

@testable import SunsetShell

/// 0035's "not done" (roadmap 0036 A): for a page, "No Icon" in the icon picker is the way back to the site's icon
/// (ADR-0063); it says so. For the other rows it keeps its name.
@MainActor
@Suite("The icon picker's way back")
struct IconClearTitleTests {
    @Test func `a page's tab, open or kept, goes back to the site's icon; a terminal's and a folder's to no icon`()
        throws
    {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://a.example/"]))
        let page = try #require(tabs.workspace.selectedID)
        tabs.newTab()
        let terminal = try #require(tabs.workspace.selectedID)
        #expect(tabs.clearIconTitle(for: .tab(page)) == "Use Site Icon")
        #expect(tabs.clearIconTitle(for: .tab(terminal)) == "No Icon")
        let kept = try #require(tabs.keep(item: page, show: false))
        #expect(tabs.clearIconTitle(for: .node(kept)) == "Use Site Icon")
        tabs.unload(entry: kept)
        #expect(tabs.clearIconTitle(for: .node(kept)) == "Use Site Icon", "not loaded: by what it starts from")
        tabs.newFolder()
        let folder = try #require(tabs.favorites.favorites.nodes.last?.id)
        #expect(tabs.clearIconTitle(for: .node(folder)) == "No Icon")
    }
}
