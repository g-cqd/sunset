import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "a tab or a window keep the mac awake as long as it is running". His answers: both ways, chosen, until it is closed or
/// until its command ends; whether the display stays on too is a setting (the app's).
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
