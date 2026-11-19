import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The Pinned grid (roadmap 0021, P-b; the owner's answers of 2026-11-17): one for the app until there are profiles, the
/// same in every Space; a tab that is pinned moves into it and is kept there; twelve at most.
@MainActor
@Suite("The Pinned grid")
struct TabsPinnedTests {
    private func window(_ pinned: FavoritesModel, made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        tabs.pinned = pinned
        return tabs
    }

    @Test func `a pinned tab leaves the Tabs for the grid, still running, and is shown as what is kept`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        tabs.newTab()
        let id = try #require(tabs.workspace.selectedID)
        #expect(tabs.canPin)
        let entry = try #require(tabs.pin(item: id))
        #expect(tabs.workspace.count == 1 && pinned.favorites.entries.map(\.id) == [entry])
        #expect(tabs.favorites.isEmpty, "not in the Space's Favorites")
        #expect(tabs.shownEntry?.id == entry && tabs.showsLive && !made.all[1].stopped && made.all[1].visible)
        let shown = try #require(tabs.shownPane)
        #expect(tabs.isPinned(entry) && tabs.content(shown) === made.all[1])
        // What ends by itself closes there; Cmd-W unloads and the entry stays.
        tabs.unload(entry: entry)
        #expect(made.all[1].stopped && pinned.favorites.entry(entry)?.isOpen == false && tabs.shownEntry == nil)
        tabs.select(entry: entry)
        #expect(pinned.favorites.entry(entry)?.isOpen == true && made.all.count == 3 && made.all[2].visible)
    }

    @Test func `the grid is the same in every window and every Space; one window draws an entry`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let first = window(pinned, made: made)
        let second = window(pinned, made: made)
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let entry = try #require(first.pin(item: tab))
        #expect(second.pinnedEntries.map(\.id) == [entry])
        second.select(entry: entry)
        #expect(second.showsLive && !first.showsLive && first.shownEntry?.id == entry)
        #expect(made.all.count == 1, "the same content, drawn elsewhere")
    }

    @Test func `unpinned, it is a tab again, running; reset, it starts again from where it was pinned`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab(.terminal(directory: "/pinned/here"))
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.pin(item: tab))
        made.all[0].descriptor = .terminal(directory: "/moved/on")
        tabs.reset(entry: entry)
        #expect(
            made.all[0].stopped && made.all.count == 2 && made.all[1].descriptor == .terminal(directory: "/pinned/here")
        )
        #expect(tabs.shownEntry?.id == entry && made.all[1].visible)
        tabs.release(entry: entry)
        #expect(pinned.favorites.isEmpty && tabs.workspace.count == 1 && !made.all[1].stopped)
        #expect(tabs.workspace.selectedItem?.panes.count == 1 && tabs.shownEntry == nil)
    }

    @Test func `twelve at most; a thirteenth is not pinned and stays a tab`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        for _ in 0 ..< TabsModel.pinnedLimit {
            tabs.newTab()
            let tab = try #require(tabs.workspace.selectedID)
            #expect(tabs.pin(item: tab, show: false) != nil)
        }
        #expect(pinned.favorites.entries.count == 12 && !tabs.canPin)
        tabs.newTab()
        let extra = try #require(tabs.workspace.selectedID)
        #expect(tabs.pin(item: extra) == nil && tabs.workspace.items.map(\.id) == [extra])
        // A window with no grid (a private one) pins nothing.
        let alone = TabsModel()
        alone.makeContent = { FakeContent($0) }
        alone.newTab()
        let lone = try #require(alone.workspace.selectedID)
        #expect(!alone.canPin && alone.pin(item: lone) == nil)
    }

    @Test func `a pinned entry is renamed and given an icon as a kept one is`() throws {
        let (pinned, made) = (FavoritesModel(), MadeContents())
        let tabs = window(pinned, made: made)
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.pin(item: tab))
        tabs.rename(.node(entry), to: "Mail")
        tabs.setIcon(.emoji("\u{2709}"), for: .node(entry))
        #expect(
            pinned.favorites.entry(entry)?.title == "Mail" && pinned.favorites.entry(entry)?.icon == .emoji("\u{2709}")
        )
        #expect(tabs.name(of: .node(entry)) == "Mail" && tabs.icon(of: .node(entry)) == .emoji("\u{2709}"))
    }
}
