import Foundation
import SunsetPane
import Testing

@testable import SunsetShellModel

/// A fully private window keeps nothing of the person's own windows (the owner's note n100, 2026-11-23): no Favorites,
/// no Pinned grid, now or after its Space's profile is followed.
@MainActor
@Suite("Private windows: nothing kept is inherited")
struct TabsPrivateWindowTests {
    @Test func `a private window starts without the app's Favorites and Pinned grid, and does not take them later`()
        throws
    {
        let shared = FavoritesModel()
        let pinned = FavoritesModel()
        let tabs = TabsModel(favorites: shared)
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = pinned
        // The person's own windows keep a favorite and a pinned tab.
        let own = TabsModel(favorites: shared)
        own.makeContent = { FakeContent($0) }
        own.pinned = pinned
        own.newTab()
        own.newTab()
        _ = try #require(own.workspace.selectedID.flatMap { own.pin(item: $0) })
        _ = try #require(own.workspace.selectedID.flatMap { own.keep(item: $0) })
        #expect(!tabs.favorites.favorites.entries.isEmpty && !tabs.pinnedEntries.isEmpty, "inherited before")
        tabs.becomePrivate(group: UUID(), shares: true)
        #expect(tabs.isPrivateWindow)
        #expect(tabs.favorites.favorites.entries.isEmpty && tabs.favorites !== shared)
        #expect(tabs.pinnedEntries.isEmpty && !tabs.canPin)
        tabs.followProfile()
        #expect(tabs.pinned == nil)
    }
}
