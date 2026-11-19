import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// 0035's "not done" (roadmap 0036 C): a kept entry (a favourite, a tile of the grid) is kept awake from its menu too; while
/// it is open, until it is closed (unloaded or deleted) or until its command ends.
@MainActor
@Suite("Keeping the Mac awake: kept entries")
struct KeepAwakeEntryTests {
    @Test func `a favourite kept awake keeps the Mac awake while it is open; unloaded, it lets go`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: tab, show: false))
        #expect(tabs.keepsAwake(entry: entry) == nil)
        tabs.keepAwake(entry: entry, until: .closed)
        #expect(tabs.keepsAwake(entry: entry) == .closed && tabs.keepsMacAwake)
        tabs.unload(entry: entry)
        #expect(!tabs.keepsMacAwake)
        tabs.settleAwake()
        #expect(tabs.keepsAwake(entry: entry) == nil, "closed: forgotten")
    }

    @Test func `a pinned tile kept awake until its command ends, seen by every window`() throws {
        let pinned = FavoritesModel()
        let first = TabsHarness()
        first.tabs.pinned = pinned
        first.tabs.newTab()
        let content = try #require(first.made.last)
        let id = try #require(first.tabs.workspace.selectedID)
        let entry = try #require(first.tabs.pin(item: id, show: false))
        let second = TabsHarness()
        second.tabs.pinned = pinned
        #expect(!first.tabs.canKeepAwakeUntilDone(entry: entry))
        content.runsCommand = true
        #expect(first.tabs.canKeepAwakeUntilDone(entry: entry))
        first.tabs.keepAwake(entry: entry, until: .commandEnds)
        #expect(second.tabs.keepsAwake(entry: entry) == .commandEnds && second.tabs.keepsMacAwake)
        content.runsCommand = false
        #expect(!first.tabs.keepsMacAwake)
        first.tabs.settleAwake()
        #expect(first.tabs.keepsAwake(entry: entry) == nil)
    }
}
