import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Something that asks for attention in a Space no window shows (a notification) marks the Space's icon until a window
/// shows it; the system's notification names the Space and goes to it, including for Favorites and Pinned entries.
@MainActor
@Suite("Activity in a Space not shown")
struct SpaceActivityTests {
    private func window(on spaces: SpacesModel, made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        tabs.show(space: spaces.spaces[0], in: spaces)
        return tabs
    }

    @Test func `a Space not shown is marked by what asks for attention in it, until a window shows it`() throws {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let made = MadeContents()
        let window = window(on: spaces, made: made)
        let home = spaces.spaces[0]
        let work = spaces.add(from: home)
        window.show(space: work, in: spaces)
        window.newTab()
        let page = try #require(made.all.last)
        #expect(spaces.space(holding: page) === work)
        work.noteActivity()
        #expect(!work.needsAttention, "shown: nothing to mark")
        window.show(space: home, in: spaces)
        work.noteActivity()
        #expect(work.needsAttention && !home.needsAttention)
        window.show(space: work, in: spaces)
        #expect(!work.needsAttention, "seen")
        #expect(spaces.space(holding: FakeContent(nil)) == nil)
    }

    @Test func `kept entries in Space-owned Favorites, profile Favorites and Pinned resolve to their Space`() throws {
        let spaces = SpacesModel(
            ownership: SpacesSession.Ownership(favoritesBySpace: true, pinnedByApp: false),
            makeFavorites: { FavoritesModel() }
        )
        let personal = spaces.profiles.profiles[0].profile.id
        let workProfile = spaces.profiles.add().profile.id
        let made = MadeContents()
        let window = window(on: spaces, made: made)
        let home = spaces.spaces[0]
        var draft = spaces.newDraft()
        draft.profile = workProfile
        let work = spaces.add(from: home, as: draft)

        // Space-owned favorite in `work`
        window.show(space: work, in: spaces)
        window.newTab()
        let favContent = try #require(made.all.last)
        let favTab = try #require(window.workspace.selectedID)
        _ = try #require(window.keep(item: favTab, show: true))

        // Pinned entry in `work`'s profile
        window.newTab()
        let pinContent = try #require(made.all.last)
        let pinTab = try #require(window.workspace.selectedID)
        let pinEntry = try #require(window.pin(item: pinTab, show: true))
        #expect(window.isPinned(pinEntry))

        // Move window back to `home` (personal profile): neither `favContent` nor `pinContent` is in `window` now.
        window.show(space: home, in: spaces)
        #expect(home.space.profile == nil || home.space.profile == personal)
        #expect(!window.reveal(favContent))
        #expect(!window.reveal(pinContent))
        #expect(spaces.space(holding: favContent) === work)
        #expect(spaces.space(holding: pinContent) === work)

        // Switching to the resolved Space reveals both, with focus on the pane!
        window.show(space: try #require(spaces.space(holding: favContent)), in: spaces)
        #expect(window.reveal(favContent) && window.selectedContent === favContent && favContent.focused)
        #expect(window.reveal(pinContent) && window.selectedContent === pinContent && pinContent.focused)
    }
}
