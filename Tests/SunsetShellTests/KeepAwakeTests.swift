import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0035 E): "a tab or a window keep the mac awake as long as it is running". His answers: both
/// ways, chosen, until it is closed or until its command ends; whether the display stays on too is a setting (the app's).
@MainActor
@Suite("Keeping the Mac awake")
struct KeepAwakeTests {
    @Test func `nothing keeps the Mac awake until a tab or the window is asked to`() {
        let harness = TabsHarness()
        harness.tabs.newTab()
        #expect(!harness.tabs.keepsMacAwake)
    }

    @Test func `a tab kept awake until it is closed keeps the Mac awake until then`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let id = try #require(tabs.workspace.selectedID)
        tabs.newTab()
        tabs.keepAwake(item: id, until: .closed)
        #expect(tabs.keepsAwake(item: id) == .closed && tabs.keepsMacAwake)
        tabs.close(item: id)
        #expect(tabs.keepsAwake(item: id) == nil && !tabs.keepsMacAwake)
    }

    @Test func `a tab kept awake until its command ends lets go when no command runs in it any more`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let id = try #require(tabs.workspace.selectedID)
        let content = try #require(harness.made.last)
        #expect(!tabs.canKeepAwakeUntilDone(item: id), "nothing runs: there is nothing to wait for")
        content.runsCommand = true
        #expect(tabs.canKeepAwakeUntilDone(item: id))
        tabs.keepAwake(item: id, until: .commandEnds)
        #expect(tabs.keepsMacAwake)
        content.runsCommand = false
        #expect(!tabs.keepsMacAwake)
        tabs.settleAwake()
        #expect(tabs.keepsAwake(item: id) == nil, "it does not wait for the next command")
        content.runsCommand = true
        #expect(!tabs.keepsMacAwake)
    }

    @Test func `turned off, a tab no longer keeps the Mac awake`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let id = try #require(tabs.workspace.selectedID)
        tabs.keepAwake(item: id, until: .closed)
        tabs.keepAwake(item: id, until: nil)
        #expect(tabs.keepsAwake(item: id) == nil && !tabs.keepsMacAwake)
    }

    @Test func `a window kept awake until it closes keeps the Mac awake whatever its tabs do`() {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        tabs.keepWindowAwake(until: .closed)
        #expect(tabs.windowAwake == .closed && tabs.keepsMacAwake)
        tabs.keepWindowAwake(until: nil)
        #expect(!tabs.keepsMacAwake)
    }

    @Test func `a window kept awake until its commands end lets go when none of its tabs runs one`() {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        tabs.newTab()
        #expect(!tabs.canKeepWindowAwakeUntilDone)
        harness.made[0].runsCommand = true
        harness.made[1].runsCommand = true
        tabs.keepWindowAwake(until: .commandEnds)
        harness.made[0].runsCommand = false
        tabs.settleAwake()
        #expect(tabs.keepsMacAwake && tabs.windowAwake == .commandEnds, "one still runs")
        harness.made[1].runsCommand = false
        #expect(!tabs.keepsMacAwake)
        tabs.settleAwake()
        #expect(tabs.windowAwake == nil)
    }

    @Test func `the windows of a Space see the same tab kept awake`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let id = try #require(first.workspace.selectedID)
        let second = harness.window()
        first.keepAwake(item: id, until: .closed)
        #expect(second.keepsAwake(item: id) == .closed)
    }
}

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
