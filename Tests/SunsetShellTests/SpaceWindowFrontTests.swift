import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Switching to the other window of a Space showed a white or black page with "Click to bring it here", "not even the
/// last snapshot". Now the window brought to the front draws the tab it shows, and the window it leaves keeps a real
/// picture of it.
@MainActor
@Suite("A Space's window brought to the front")
struct SpaceWindowFrontTests {
    @Test func `the window brought to the front draws the tab it shows`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let second = harness.window()
        second.select(item: tab)
        #expect(!first.showsLive && second.showsLive)
        first.cameToFront()
        #expect(first.showsLive && !second.showsLive)
        #expect(harness.wired.last?.window == ObjectIdentifier(first), "what it asks for is asked of the front window")
    }

    @Test
    func `a window brought to the front that already draws what it shows, or shows nothing, takes nothing`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let second = harness.window()
        second.cameToFront()
        #expect(first.showsLive && second.workspace.selectedID == nil)
        second.select(item: tab)
        second.cameToFront()
        #expect(second.showsLive && !first.showsLive)
    }

    @Test func `a kept entry shown in two windows is drawn by the one brought to the front`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let entry = try #require(first.keep(item: tab))
        let second = harness.window()
        second.select(entry: entry)
        #expect(!first.showsLive && second.showsLive)
        first.cameToFront()
        #expect(first.showsLive && !second.showsLive)
    }

    @Test func `the window a tab leaves is left a picture of it`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let content = try #require(harness.content(tab: 0))
        let second = harness.window()
        #expect(content.pictures == 0)
        second.select(item: tab)
        #expect(content.pictures == 1, "taken as it moves")
        first.cameToFront()
        #expect(content.pictures == 2)
    }

    @Test func `the window a kept entry leaves is left a picture of it`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let content = try #require(harness.content(tab: 0))
        let entry = try #require(first.keep(item: tab))
        let second = harness.window()
        let before = content.pictures
        second.select(entry: entry)
        #expect(content.pictures == before + 1)
    }
}
