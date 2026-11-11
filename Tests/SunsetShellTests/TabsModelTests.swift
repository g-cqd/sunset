import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("The tabs of a window") struct TabsModelTests {
    /// A tab model that makes `FakeContent`s, with what it made, the number of changes it reported and whether it said it was empty.
    @MainActor final class Harness {
        let tabs = TabsModel()
        var made: [FakeContent] = []
        var changes = 0
        var emptied = false

        init() {
            tabs.makeContent = { [weak self] descriptor in
                let content = FakeContent(descriptor)
                self?.made.append(content)
                return content
            }
            tabs.onChange = { [weak self] in self?.changes += 1 }
            tabs.onEmpty = { [weak self] in self?.emptied = true }
        }

        func content(_ pane: PaneID) -> FakeContent? { tabs.contents[pane] as? FakeContent }
    }

    @Test func `a new tab gets content from the app, and only the shown, focused pane is told so`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        #expect(harness.made.count == 2 && harness.changes > 0)
        let first = try #require(harness.content(harness.tabs.workspace.items[0].focused))
        let second = try #require(harness.content(harness.tabs.workspace.items[1].focused))
        #expect(!first.visible && !first.focused)
        #expect(second.visible && second.focused)
        harness.tabs.newSplit(.right)
        #expect(!second.focused && second.visible, "the new pane beside it has the keyboard")
        harness.tabs.select(index: 0)
        #expect(first.visible && first.focused && !second.visible)
    }

    @Test func `a pane whose program ends closes, and the last one empties the window`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        let content = try #require(harness.made.first)
        content.onExit()
        #expect(content.stopped && harness.tabs.workspace.isEmpty && harness.emptied)
    }

    @Test func `closing a tab whose content would lose something asks twice; an idle one closes at once`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        let busy = try #require(harness.made.last)
        busy.closeWarning = "make is running"
        let item = harness.tabs.workspace.items[1].id
        harness.tabs.close(item: item)
        #expect(harness.tabs.workspace.count == 2 && harness.tabs.isCloseArmed(item) && !busy.stopped)
        harness.tabs.close(item: item)
        #expect(harness.tabs.workspace.count == 1 && busy.stopped)
        harness.tabs.close(item: harness.tabs.workspace.items[0].id)
        #expect(harness.tabs.workspace.isEmpty && harness.emptied)
    }

    @Test func `with confirmation off, a busy tab closes at once`() throws {
        let harness = Harness()
        harness.tabs.confirmClose = false
        harness.tabs.newTab()
        try #require(harness.made.first).closeWarning = "busy"
        harness.tabs.closeSelected()
        #expect(harness.tabs.workspace.isEmpty)
    }

    @Test
    func `a saved window comes back with a content made from each pane's descriptor, new ones where none was saved`() {
        var workspace = Workspace()
        let one = workspace.add()
        let two = workspace.add()
        let saved = SavedWindow(
            workspace: workspace,
            contents: [one.pane: PaneDescriptor(kind: "note", state: ["text": "hi"])]
        )
        let harness = Harness()
        harness.tabs.restore(saved)
        #expect(harness.tabs.workspace == workspace)
        #expect(harness.content(one.pane)?.descriptor.kind == "note")
        #expect(harness.content(two.pane)?.descriptor == .terminal(directory: nil))
        #expect(harness.tabs.savedWindow().contents[one.pane]?.state == ["text": "hi"])
    }

    @Test func `a saved window with no tab of its own starts with a new one, and a window with tabs is not replaced`() {
        let harness = Harness()
        harness.tabs.restore(SavedWindow(workspace: Workspace()))
        #expect(harness.tabs.workspace.count == 1)
        var other = Workspace()
        other.add()
        other.add()
        harness.tabs.restore(SavedWindow(workspace: other))
        #expect(harness.tabs.workspace.count == 1)
    }

    @Test func `a pane taken out keeps running, and is not stopped`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        harness.tabs.newSplit(.bottom)
        let pane = try #require(harness.tabs.workspace.selectedPane)
        let taken = harness.tabs.detach(pane: pane) as? FakeContent
        #expect(taken != nil && taken?.stopped == false && harness.tabs.contents[pane] == nil)
        #expect(harness.tabs.workspace.allPanes.count == 1)
    }

    @Test func `tabs are found by their name, their content's title and detail, and what the content adds`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        let first = try #require(harness.made.first)
        first.title = "zsh"
        first.detail = "~/src"
        first.searchTerms = ["cargo"]
        harness.tabs.rename(item: harness.tabs.workspace.items[1].id, to: "logs", icon: nil)
        let fields = harness.tabs.fields(of: harness.tabs.workspace.items[0])
        #expect(fields == ["zsh", "~/src", "cargo"])
        var bar = CommandBar(purpose: .search)
        bar.query = "cargo"
        #expect(harness.tabs.barResults(bar).map(\.id) == [harness.tabs.workspace.items[0].id])
        bar.query = "logs"
        #expect(harness.tabs.barResults(bar).map(\.id) == [harness.tabs.workspace.items[1].id])
    }

    @Test func `a content asking for the keyboard gets it only while its tab is shown`() throws {
        let harness = Harness()
        harness.tabs.newTab()
        harness.tabs.newSplit(.right)
        harness.tabs.newTab()
        let hidden = try #require(harness.made.first)
        hidden.onFocusRequest()
        #expect(harness.tabs.workspace.selectedIndex == 1, "a hidden pane does not take its tab back")
        harness.tabs.select(index: 0)
        hidden.onFocusRequest()
        #expect(hidden.focused)
    }
}
