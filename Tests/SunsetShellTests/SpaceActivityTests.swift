import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Something that asks for attention in a Space no window shows (a notification) marks the Space's icon until a window
/// shows it; the system's notification names the Space and goes to it.
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
}
