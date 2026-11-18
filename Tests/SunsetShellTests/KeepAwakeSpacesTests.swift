import SunsetPane
import Testing

@testable import SunsetShell

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
