import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner (2026-11-21): two favorite tabs could not be split; only pinned tabs should refuse being split by drag and
/// drop, and a split tab can still be pinned.
@MainActor
@Suite("Favorites split")
struct FavoritesSplitTests {
    private func window(pinned: FavoritesModel = FavoritesModel()) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = pinned
        return tabs
    }

    @Test func `a favorite dragged onto a tab's half joins it as a split, leaving the Favorites`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let target = tabs.workspace.items[0].id
        _ = tabs.itemProvider(for: .entry(kept))
        #expect(tabs.canDrop(onto: target, action: .split(.right)))
        #expect(tabs.dropDragged(onto: target, action: .split(.right)))
        let joined = try #require(tabs.workspace.items.first { $0.id == target })
        #expect(joined.panes.count == 2, "the favorite's pane beside the tab's")
        #expect(tabs.favorites.favorites.entry(kept) == nil, "it left the Favorites")
        #expect(tabs.workspace.count == 2)
    }

    @Test func `a favorite dragged onto a pane's edge joins that tab as a split`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let kept = try #require(tabs.keep(item: tabs.workspace.items[0].id))
        let target = tabs.workspace.items[0]
        _ = tabs.itemProvider(for: .entry(kept))
        #expect(tabs.canDrop(onto: target.focused))
        #expect(tabs.dropDragged(onto: target.focused, edge: .bottom))
        #expect(tabs.workspace.items.first { $0.id == target.id }?.panes.count == 2)
    }

    @Test func `a pinned tab is not split by drag and drop`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        let target = tabs.workspace.items[0]
        _ = tabs.itemProvider(for: .entry(pinned))
        #expect(!tabs.canDrop(onto: target.id, action: .split(.right)))
        #expect(!tabs.canDrop(onto: target.focused))
    }

    @Test func `a split tab can be pinned`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newSplit(.right)
        let split = try #require(tabs.workspace.selectedID)
        #expect(tabs.workspace.items.first { $0.id == split }?.panes.count == 2)
        let entry = try #require(tabs.pin(item: split))
        #expect(tabs.pinned?.favorites.entry(entry)?.home.contents.count == 2)
    }

    @Test func `favorites selected with tabs are offered the layouts, and leave the Favorites to be laid out`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let first = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        let second = try #require(tabs.keep(item: tabs.workspace.items[0].id, show: false))
        let tab = tabs.workspace.items[0].id
        let rows: [RowTarget] = [.node(first), .node(second), .tab(tab)]
        #expect(tabs.layoutRows(rows).count == 3)
        #expect(tabs.layoutPresets(for: rows).contains(.threeColumns))
        tabs.apply(.threeColumns, to: rows)
        #expect(tabs.favorites.isEmpty, "both favorites left for the split")
        #expect(tabs.workspace.count == 1 && tabs.workspace.items[0].panes.count == 3)
    }

    @Test func `pinned tabs are not laid out with others`() throws {
        let tabs = window()
        tabs.newTab()
        tabs.newTab()
        let pinned = try #require(tabs.pin(item: tabs.workspace.items[0].id, show: false))
        let rows: [RowTarget] = [.node(pinned), .tab(tabs.workspace.items[0].id)]
        #expect(tabs.layoutRows(rows).count == 1)
        #expect(tabs.layoutPresets(for: rows).isEmpty)
    }
}
