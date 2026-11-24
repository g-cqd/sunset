import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A tab of the window's list, a document's included, can be unloaded by hand: it stays in the list, drawn as not loaded, and is
/// made again from where it was when shown.
@MainActor @Suite("Unloading a tab of the list")
struct UnloadingATabTests {
    private let document = PaneDescriptor.document(file: "/tmp/notes.md")

    @Test func `a tab no window shows lets go of its content and waits; shown, it is made again`() throws {
        let harness = SpaceHarness()
        let window = harness.window()
        window.newTab(document)
        window.newTab(.terminal(directory: "/b"))
        let (other, shown) = (window.workspace.items[0], window.workspace.items[1])
        let content = try #require(window.content(other.focused))

        #expect(window.canUnload(item: other.id), "a document that is not on screen")
        #expect(window.unload(item: other.id))
        #expect(content is FakeContent && (content as? FakeContent)?.stopped == true)
        #expect(window.content(other.focused) == nil && window.workspace.count == 2)
        #expect(window.pendingDescriptor(other.focused) == document, "what it starts from")
        #expect(harness.space.saved().contents[other.focused] == document, "still in the session")

        window.select(item: other.id)
        #expect(window.content(other.focused)?.descriptor == document)
        _ = shown
    }

    @Test func `the tab on screen unloads too: the window goes back to the tab it showed before`() throws {
        let harness = SpaceHarness()
        let window = harness.window()
        window.newTab(.terminal(directory: "/a"))
        window.newTab(document)
        window.newTab(.terminal(directory: "/c"))
        let (a, b, c) = (window.workspace.items[0], window.workspace.items[1], window.workspace.items[2])
        window.select(item: b.id)
        window.select(item: c.id)
        #expect(window.canUnload(item: c.id))
        #expect(window.unload(item: c.id))
        #expect(window.workspace.selectedID == b.id, "back to the tab shown before")
        #expect(window.content(c.focused) == nil && window.workspace.count == 3, "it stays in the list")
        #expect(window.pendingDescriptor(c.focused) == .terminal(directory: "/c"))
        window.select(item: c.id)
        #expect(window.content(c.focused) != nil)
        _ = a
    }

    @Test func `the only tab, or a tab another window shows, is not unloaded`() throws {
        let harness = SpaceHarness()
        let first = harness.window()
        first.newTab(document)
        let only = first.workspace.items[0]
        #expect(!first.canUnload(item: only.id), "nowhere to go")
        first.newTab(.terminal(directory: "/b"))
        let second = harness.window()
        second.select(item: only.id)
        #expect(!first.canUnload(item: only.id), "another window shows it")
        #expect(!second.canUnload(item: only.id) || second.workspace.items.count > 1)
    }

    @Test func `an idle terminal unloads and starts again where it was; one running a command stays`() throws {
        let harness = SpaceHarness()
        let window = harness.window()
        window.newTab(.terminal(directory: "/idle"))
        window.newTab(.terminal(directory: "/busy"))
        window.newTab(document)
        let (idle, busy) = (window.workspace.items[0], window.workspace.items[1])
        try #require(harness.content(busy.focused)).runsCommand = true
        #expect(window.canUnload(item: idle.id) && !window.canUnload(item: busy.id))
        #expect(!window.unload(item: busy.id) && window.content(busy.focused) != nil)
        #expect(window.unload(item: idle.id) && window.content(idle.focused) == nil)
        window.select(item: idle.id)
        #expect(window.content(idle.focused)?.descriptor == .terminal(directory: "/idle"))
    }

    @Test func `a page unloads where it is, keeping its tab and its place; text typed and not sent stops it`()
        async throws
    {
        let harness = SpaceHarness()
        let window = harness.window()
        let page = PaneDescriptor(kind: "web", state: ["url": "https://a.example/"])
        window.newTab(page)
        window.newTab(page)
        window.newTab(.terminal(directory: "/shown"))
        let (first, second) = (window.workspace.items[0], window.workspace.items[1])
        for tab in [first, second] { try #require(harness.content(tab.focused)).unloadsInPlace = true }
        try #require(harness.content(second.focused)).unsentText = true
        #expect(window.canUnload(item: first.id))

        #expect(await window.unloadChecked(item: first.id) == .done("Unloaded"))
        let kept = try #require(harness.content(first.focused))
        #expect(kept.unloads == 1 && kept.isUnloaded && !kept.stopped, "the page stays, its view let go of")
        #expect(window.workspace.count == 3)
        #expect(!window.canUnload(item: first.id), "already unloaded")

        let typed = await window.unloadChecked(item: second.id)
        #expect(typed == .blocked("Something typed in it is not sent"))
        #expect(try #require(harness.content(second.focused)).unloads == 0)
    }
}
