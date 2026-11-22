import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A Space's tabs in several windows: the windows list the same tabs, each with its own selection; a tab is drawn and
/// typed into in one window, the one that last clicked it.
@MainActor
@Suite("A Space in several windows")
struct SpaceSharingTests {
    @Test func `a new window on a Space has nothing selected; a tab made in one window is listed in the other`() {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        first.newTab()
        let second = harness.window()
        #expect(second.workspace.items == first.workspace.items && second.workspace.count == 2)
        #expect(second.workspace.selectedID == nil && second.shownItem == nil && second.selectedContent == nil)
        second.newTab()
        #expect(first.workspace.count == 3 && first.workspace.selectedID == first.workspace.items[1].id)
        #expect(second.workspace.selectedID == second.workspace.items[2].id, "after the others: nothing was selected")
        #expect(harness.content(tab: 2)?.visible == true && harness.content(tab: 1)?.visible == true)
    }

    @Test func `a tab is live in one window: the one that clicked it last; the other shows its picture`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let second = harness.window()
        #expect(first.showsLive && harness.content(tab: 0)?.focused == true)
        second.select(item: tab)
        #expect(second.showsLive && !first.showsLive, "the click takes it")
        #expect(first.workspace.selectedID == tab, "the first still has it selected: it shows the picture")
        #expect(harness.content(tab: 0)?.visible == true && harness.content(tab: 0)?.focused == true)
        #expect(
            harness.wired.last?.window == ObjectIdentifier(second),
            "what it asks for is asked of the window that draws it"
        )
        // A click on the tab that is already selected, or on its picture, takes it back.
        first.select(item: tab)
        #expect(first.showsLive && !second.showsLive)
        second.takeShown()
        #expect(second.showsLive && !first.showsLive)
    }

    @Test func `leaving a tab gives it to a window that still shows it; with none it is hidden`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        first.newTab()
        let (one, two) = (first.workspace.items[0].id, first.workspace.items[1].id)
        let second = harness.window()
        second.select(item: two)
        #expect(!first.showsLive && second.showsLive)
        second.select(item: one)
        #expect(first.showsLive, "the first still had it selected: it draws it again")
        #expect(harness.content(tab: 1)?.visible == true && harness.content(tab: 0)?.visible == true)
        first.select(item: one)
        #expect(harness.content(tab: 1)?.visible == false, "no window shows it")
        #expect(first.showsLive && !second.showsLive)
    }

    @Test
    func `a tab closed in one window goes from the other, which moves to a neighbour without taking it from anyone`()
        throws
    {
        let harness = SpaceHarness()
        let first = harness.window()
        for _ in 0 ..< 3 { first.newTab() }
        let ids = first.workspace.items.map(\.id)
        let second = harness.window()
        second.select(item: ids[1])
        first.select(item: ids[2])
        let closing = try #require(harness.content(tab: 1))
        first.close(item: ids[1])
        #expect(closing.stopped && second.workspace.items.map(\.id) == [ids[0], ids[2]])
        #expect(second.workspace.selectedID == ids[2], "the neighbour")
        #expect(first.showsLive && !second.showsLive, "it is the first's: the second shows its picture")
        // A program that ends by itself closes its tab for every window.
        harness.content(tab: 0)?.onExit()
        #expect(first.workspace.count == 1 && second.workspace.count == 1)
        harness.content(tab: 0)?.onExit()
        #expect(harness.space.tabs.isEmpty && harness.emptied.count == 2, "the last tab: each window is told")
    }

    @Test func `a window that closes stops nothing while another shows the Space, and gives what it drew`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab()
        let tab = try #require(first.workspace.selectedID)
        let second = harness.window()
        second.select(item: tab)
        first.select(item: tab)
        first.windowClosed()
        #expect(harness.content(tab: 0)?.stopped == false && second.showsLive)
        #expect(harness.space.tabs.count == 1 && harness.space.viewerCount == 1)
    }

    /// "they stay, stop".
    @Test
    func `the last window of a Space closes: its tabs stop and stay, and start again where they were in the next`()
        throws
    {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab(.terminal(directory: "/work"))
        first.newTab(PaneDescriptor(kind: "fake", state: ["k": "v"]))
        let running = harness.made
        first.windowClosed()
        #expect(running.allSatisfy(\.stopped) && harness.space.contents.isEmpty)
        #expect(harness.space.tabs.count == 2 && harness.space.isStopped)
        #expect(harness.space.saved().contents.values.contains(.terminal(directory: "/work")), "still in the session")
        let next = harness.window()
        #expect(harness.made.count == 4 && !harness.space.isStopped)
        #expect(
            harness.made[2].descriptor == .terminal(directory: "/work")
                && harness.made[3].descriptor.state == ["k": "v"]
        )
        #expect(next.workspace.count == 2 && next.workspace.selectedID == nil)
    }

    @Test func `a Space that does not keep its tabs (a private window, a window that is one tab) ends them with it`() {
        let harness = SpaceHarness(keepsTabs: false)
        let only = harness.window()
        only.newTab()
        only.windowClosed()
        #expect(harness.made[0].stopped && !harness.space.isStopped && harness.space.tabs.isEmpty)
    }

    /// A setting (`tabs.closeWithLastWindow`): the app's Space can be told not to keep them, while it runs.
    @Test func `a Space told to close its tabs with its last window closes them; told again, it keeps them`() {
        let harness = SpaceHarness()
        harness.space.keepsTabs = false
        let first = harness.window()
        first.newTab()
        first.windowClosed()
        #expect(harness.space.tabs.isEmpty && harness.space.contents.isEmpty && harness.made[0].stopped)
        #expect(harness.space.saved().tabs.isEmpty)
        harness.space.keepsTabs = true
        let second = harness.window()
        second.newTab()
        second.windowClosed()
        #expect(harness.space.tabs.count == 1 && harness.space.isStopped)
    }

    /// A setting (`tabs.closeStoppedAfter`): what was stopped is closed once it has waited long enough, even across a
    /// quit (the time it was stopped is in the session).
    @Test
    func `tabs stopped with the last window are closed once they have waited long enough, not before, not once shown`()
    {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab(.terminal(directory: "/a"))
        let closed = Date(timeIntervalSince1970: 1000)
        first.windowClosed(at: closed)
        #expect(harness.space.stopped == closed && harness.space.saved().stopped == closed)
        #expect(!harness.space.closeStopped(after: 3600, now: closed.addingTimeInterval(3599)))
        #expect(harness.space.tabs.count == 1)
        // Across a quit: read back, still waiting from the same moment.
        let other = SpaceHarness()
        other.space.restore(harness.space.saved())
        #expect(other.space.isStopped && other.space.stopped == closed)
        #expect(other.space.closeStopped(after: 3600, now: closed.addingTimeInterval(3600)))
        #expect(other.space.tabs.isEmpty && !other.space.isStopped && other.space.saved().stopped == nil)
        // Shown again in time, they are no longer waiting.
        let next = harness.window()
        #expect(harness.space.stopped == nil && next.workspace.count == 1)
        #expect(!harness.space.closeStopped(after: 3600, now: closed.addingTimeInterval(99_999)))
        // A Space with windows, or with nothing stopped, has nothing to close; 0 is never.
        next.windowClosed(at: closed)
        #expect(!harness.space.closeStopped(after: 0, now: closed.addingTimeInterval(99_999)))
    }

    @Test func `what is saved: the Space once, without what is private, and a view for each window`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab(.terminal(directory: "/a"))
        first.newTab(.terminal(directory: "/b"))
        harness.made[1].isPrivate = true
        let second = harness.window()
        second.select(item: first.workspace.items[0].id)
        let saved = harness.space.saved()
        #expect(saved.space.id == harness.space.space.id && saved.tabs.count == 1)
        #expect(saved.contents.values.map(\.directory) == ["/a"])
        #expect(first.savedView() == SavedView(space: saved.space.id, selected: nil), "its tab was private")
        #expect(second.savedView() == SavedView(space: saved.space.id, selected: saved.tabs.items[0].id))
    }

    @Test func `a saved Space comes back, and each window shows what its view had selected`() throws {
        let harness = SpaceHarness()
        var tabs = Workspace()
        let (a, b) = (tabs.add(after: .end), tabs.add(after: .end))
        let saved = SavedSpace(
            space: Space(name: "Work"),
            tabs: tabs,
            contents: [a.pane: .terminal(directory: "/a"), b.pane: .terminal(directory: "/b")]
        )
        harness.space.restore(saved)
        #expect(harness.space.space.name == "Work" && harness.space.contents.isEmpty, "nothing is made with no window")
        let first = harness.window()
        first.show(SavedView(space: saved.space.id, selected: b.item))
        let second = harness.window()
        second.show(SavedView(space: saved.space.id, selected: b.item))
        #expect(harness.made.map(\.descriptor.directory) == ["/a", "/b"], "made once, by the first window")
        #expect(first.showsLive && !second.showsLive && second.workspace.selectedID == b.item)
        #expect(harness.content(b.pane)?.visible == true && harness.content(a.pane)?.visible == false)
    }
}
