import SunsetPane
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0038 A): "Moving a tab to the favorites makes it lose its keep awake status". What is kept
/// awake is the tab, wherever it goes: Today, the Favorites, the grid, another window.
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

/// The owner's note n25 (2026-11-18): "the keep awake … of a tab is removed when switching spaces, this should be fixed, even
/// across profiles". A Space left runs on, and so does what it keeps awake.
@MainActor
@Suite("Keeping the Mac awake across Spaces")
struct KeepAwakeSpacesTests {
    private func window(on spaces: SpacesModel) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.show(space: spaces.spaces[0], in: spaces)
        return tabs
    }

    @Test(arguments: [false, true])
    func `a tab kept awake stays so while its window shows another Space`(otherProfile: Bool) throws {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let window = window(on: spaces)
        window.newTab()
        let tab = try #require(window.workspace.selectedID)
        window.keepAwake(item: tab, until: .closed)
        let home = spaces.spaces[0]
        let work = spaces.add(from: home)
        if otherProfile { spaces.setProfile(spaces.profiles.add().profile.id, for: work) }
        window.show(space: work, in: spaces)
        TabsModel.settleAwake(in: [window])
        #expect(window.keepsMacAwake, "the Space left still keeps the Mac awake")
        window.show(space: home, in: spaces)
        TabsModel.settleAwake(in: [window])
        #expect(window.keepsAwake(item: tab) == .closed, "and its tab is still kept awake on coming back")
    }
}

extension KeepAwakeSpacesTests {
    @Test func `a pinned page kept awake stays so while its window shows a Space of another profile`() throws {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let window = window(on: spaces)
        window.newTab()
        let tab = try #require(window.workspace.selectedID)
        window.keepAwake(item: tab, until: .closed)
        let entry = try #require(window.keep(item: tab, show: false))
        #expect(window.pin(entry: entry))
        let home = spaces.spaces[0]
        let work = spaces.add(from: home)
        spaces.setProfile(spaces.profiles.add().profile.id, for: work)
        window.show(space: work, in: spaces)
        TabsModel.settleAwake(in: [window])
        #expect(window.keepsMacAwake, "the other profile's grid still keeps the Mac awake")
        window.show(space: home, in: spaces)
        #expect(window.keepsAwake(entry: entry) == .closed)
    }
}
