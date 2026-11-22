import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sidebar's lines stand between parts, never after the last one shown (the owner's note n87); the empty window's hint
/// says what ⌘T makes (n81).
@MainActor
@Suite("The sidebar's lines and the empty window's hint")
struct SidebarLinesTests {
    private func window(_ pinned: FavoritesModel) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0 ?? .terminal(directory: nil)) }
        tabs.pinned = pinned
        return tabs
    }

    @Test func `the line under the Pinned grid shows only with something under it`() throws {
        let tabs = window(FavoritesModel())
        tabs.newTab()
        tabs.newTab()
        let pinnedID = try #require(tabs.workspace.selectedID)
        _ = try #require(tabs.pin(item: pinnedID))
        #expect(tabs.linesShown.afterPinned, "a tab under the grid")
        let last = try #require(tabs.workspace.selectedID)
        tabs.close(item: last)
        #expect(tabs.workspace.isEmpty)
        #expect(!tabs.linesShown.afterPinned, "nothing under it")
        #expect(!tabs.linesShown.afterFavorites)
    }

    @Test func `the empty window's hint says a terminal only when terminals are on`() {
        let tabs = window(FavoritesModel())
        #expect(tabs.emptyHint == "No tab. \u{2318}T for a terminal")
        tabs.scopes = Scopes(terminal: false)
        #expect(tabs.emptyHint == "No tab. \u{2318}T to open one")
    }
}
