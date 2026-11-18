import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// The owner's note n3 (2026-11-18): "the pinned tabs that have navigated away from their pinned origin should show a visual
/// cue that they're not loaded on the origin, and … a double click on a pinned tab or a favorite tab should reset it to its
/// origin (… favorites tab as well)".
@MainActor @Suite("A kept page away from where it was kept")
struct KeptEntryAwayTests {
    @Test func `away once its page is elsewhere; a double click takes it back; at home it renames as before`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        var made: [FakeContent] = []
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.append(content)
            return content
        }
        tabs.pinned = pinned
        tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://mail.example/inbox"]))
        let item = try #require(tabs.workspace.selectedID)
        let pinnedEntry = tabs.pin(item: item)
        let entry = try #require(pinnedEntry)
        let kept = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: kept), "where it was kept")
        let page = try #require(made.last)
        page.descriptor = PaneDescriptor(kind: "web", state: ["url": "https://mail.example/inbox#unread"])
        #expect(!tabs.isAway(entry: kept), "a fragment is the same page")
        page.descriptor = PaneDescriptor(kind: "web", state: ["url": "https://mail.example/message/42"])
        let moved = try #require(pinned.favorites.entry(entry))
        #expect(tabs.isAway(entry: moved))
        tabs.doubleClick(entry: entry)
        let back = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: back) && tabs.renamingRow == nil, "taken back, not renamed")
        tabs.doubleClick(entry: entry)
        #expect(tabs.renamingRow == .node(entry), "at home, a double click renames")
    }

    @Test func `a terminal is never away: its folder changes as it works`() throws {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        var made: [FakeContent] = []
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.append(content)
            return content
        }
        tabs.pinned = pinned
        tabs.newTab(.terminal(directory: "/tmp"))
        let item = try #require(tabs.workspace.selectedID)
        let pinnedEntry = tabs.pin(item: item)
        let entry = try #require(pinnedEntry)
        try #require(made.last).descriptor = .terminal(directory: "/usr")
        let worked = try #require(pinned.favorites.entry(entry))
        #expect(!tabs.isAway(entry: worked))
    }
}
