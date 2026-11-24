import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// How a window comes to a Space, and what is then its own to do.
@MainActor
@Suite("A window joins a Space")
struct SpaceJoiningTests {
    /// How a window comes to a Space: it starts with one of its own, and joins (the app's, or when the tabs go from a
    /// window each to one list).
    @Test
    func `a window joins a Space: the tabs it had go after the Space's, still running, and it keeps its selection`()
        throws
    {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let own = TabsHarness()
        own.tabs.newTab()
        own.tabs.newTab()
        let selected = try #require(own.tabs.workspace.selectedID)
        let moved = own.made
        own.tabs.join(harness.space)
        #expect(own.tabs.space === harness.space && harness.space.viewerCount == 2)
        #expect(first.workspace.count == 3 && own.tabs.workspace.items == first.workspace.items)
        #expect(own.tabs.workspace.selectedID == selected && own.tabs.showsLive)
        #expect(moved.allSatisfy { !$0.stopped } && moved[1].visible && !moved[0].visible)
        // What ends by itself is the Space's to close now.
        moved[0].onExit()
        #expect(first.workspace.count == 2 && moved[0].stopped)
        // A window that joins with nothing has nothing selected.
        let empty = TabsHarness()
        empty.tabs.join(harness.space)
        #expect(empty.tabs.workspace.selectedID == nil && empty.tabs.workspace.count == 2)
    }

    @Test func `what a window draws, or no window does, is the window's to set up; what another draws is not`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        first.newTab()
        let ids = first.workspace.items.map(\.id)
        let second = harness.window()
        #expect(first.drawnPanes.count == 2 && second.drawnPanes.count == 1, "the one no window draws")
        second.select(item: ids[1])
        #expect(first.drawnPanes == first.workspace.items[0].panes && second.drawnPanes.count == 2)
    }

    @Test func `closing a window asks about unsaved edits only when it is the last of its Space`() {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        harness.made[0].edits = FakeEdits("a.md")
        let second = harness.window()
        #expect(!first.windowHoldsUnsaved && !second.windowHoldsUnsaved, "the other window still shows them")
        var closed = false
        first.closeWindow { closed = true }
        #expect(closed && first.unsavedQuestion == nil)
        first.windowClosed()
        #expect(second.windowHoldsUnsaved)
    }

    /// Seen 2026-11-16: the saved tabs came back as "A document pane. This version of Sunset cannot show it".
    @Test func `a window that joins before it can make content makes none: the tabs wait for it to say how`() {
        let harness = SpaceHarness()
        var tabs = Workspace()
        let pane = tabs.add(after: .end).pane
        harness.space.restore(SavedSpace(space: Space(), tabs: tabs, contents: [pane: .terminal(directory: "/a")]))
        let window = TabsModel()
        window.join(harness.space)
        #expect(harness.space.contents.isEmpty, "no placeholder is made of a pane that has a kind")
        window.makeContent = { FakeContent($0) }
        #expect(harness.space.contents.isEmpty, "a tab that is not shown waits")
        window.select(item: harness.space.tabs.items[0].id)
        #expect(harness.space.contents[pane]?.descriptor == .terminal(directory: "/a"))
    }
}
