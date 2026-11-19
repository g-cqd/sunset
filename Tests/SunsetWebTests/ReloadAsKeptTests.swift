import Foundation
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner, 2026-11-19: "a tab reloaded as another profile and then moved to favorites, loses its profile attribution and
/// loads then as the current profile"; and its mark should show even while it is not loaded.
@MainActor @Suite("Reload as: kept in the Favorites")
struct ReloadAsKeptTests {
    private static let workID = UUID()

    private func model(home: UUID? = nil) -> TabsModel {
        let tabs = TabsModel(favorites: FavoritesModel())
        var settings = WebSettings()
        settings.profile = home
        tabs.makeContent = { descriptor in
            WebContent(descriptor: descriptor ?? PaneDescriptor(kind: WebContent.kind), settings: settings)
        }
        return tabs
    }

    @Test func `from another profile's Space, reloaded as the first profile, kept and opened again`() throws {
        let tabs = model(home: Self.workID)
        tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": "https://example.org/"]))
        let item = try #require(tabs.workspace.selectedID)
        let pane = try #require(tabs.workspace.selectedItem?.focused)
        let page = try #require(tabs.content(pane) as? WebContent)
        page.reload(as: nil)
        let entry = try #require(tabs.keep(item: item, show: false))
        tabs.unload(entry: entry)
        tabs.select(entry: entry)
        let open = try #require(tabs.favorites.favorites.entry(entry)?.open?.focused)
        let again = try #require(tabs.content(open) as? WebContent)
        #expect(again.settings.profile == nil && again.reloadedAs == OtherProfile(id: nil))
    }

    @Test func `a page reloaded as another profile keeps it in the Favorites, unloaded and opened again`() throws {
        let tabs = model()
        tabs.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": "https://example.org/"]))
        let item = try #require(tabs.workspace.selectedID)
        let pane = try #require(tabs.workspace.selectedItem?.focused)
        let page = try #require(tabs.content(pane) as? WebContent)
        page.reload(as: Self.workID)
        let entry = try #require(tabs.keep(item: item, show: false))
        let kept = try #require(tabs.favorites.favorites.entry(entry))
        #expect(kept.home.contents.values.first?.state["as"] == Self.workID.uuidString, "its home says so")
        tabs.unload(entry: entry)
        tabs.select(entry: entry)
        let open = try #require(tabs.favorites.favorites.entry(entry)?.open?.focused)
        let again = try #require(tabs.content(open) as? WebContent)
        #expect(again.settings.profile == Self.workID && again.reloadedAs == OtherProfile(id: Self.workID))
    }
}
