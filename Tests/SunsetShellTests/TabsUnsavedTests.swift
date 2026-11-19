import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Closing what holds unsaved edits asks Save, Don't Save or Cancel (R6, roadmap 0023 step M-d), whatever closes it: a pane,
/// a tab, the other tabs, the window. A document is lost only when the panes that go are all the panes that show it.
@MainActor
@Suite("Closing with unsaved edits asks")
struct TabsUnsavedTests {
    private func window(_ count: Int) -> TabsHarness {
        let harness = TabsHarness()
        for _ in 0 ..< count { harness.tabs.newTab() }
        return harness
    }

    private func edit(_ harness: TabsHarness, _ index: Int, _ title: String = "notes.md") -> FakeEdits {
        let edits = FakeEdits(title)
        harness.made[index].edits = edits
        return edits
    }

    @Test func `closing a tab with edits asks, and nothing closes until it is answered`() {
        let harness = window(2)
        let edits = edit(harness, 1)
        harness.tabs.close(item: harness.tabs.workspace.items[1].id)
        #expect(harness.tabs.unsavedQuestion?.documents.map(\.title) == ["notes.md"])
        #expect(harness.tabs.workspace.count == 2 && !harness.made[1].stopped && edits.saved == 0)
        #expect(!harness.tabs.isCloseArmed(harness.tabs.workspace.items[1].id), "it is a sheet, not the red tab")
    }

    @Test func `Save writes and closes; a save that fails closes nothing`() {
        let harness = window(2)
        let edits = edit(harness, 1)
        edits.saves = false
        harness.tabs.closeSelected()
        harness.tabs.answerUnsaved(.save)
        #expect(edits.saved == 1 && harness.tabs.workspace.count == 2 && harness.tabs.unsavedQuestion == nil)
        edits.saves = true
        harness.tabs.closeSelected()
        harness.tabs.answerUnsaved(.save)
        #expect(edits.saved == 2 && harness.tabs.workspace.count == 1 && harness.made[1].stopped)
    }

    @Test func `Don't Save gives the edits up and closes; Cancel keeps everything`() {
        let harness = window(2)
        let edits = edit(harness, 1)
        harness.tabs.closeSelected()
        harness.tabs.answerUnsaved(.cancel)
        #expect(harness.tabs.workspace.count == 2 && edits.discarded == 0 && harness.tabs.unsavedQuestion == nil)
        harness.tabs.closeSelected()
        harness.tabs.answerUnsaved(.discard)
        #expect(harness.tabs.workspace.count == 1 && edits.discarded == 1 && edits.saved == 0)
    }

    @Test func `a pane closes without a word while another pane shows the same document`() {
        let harness = window(1)
        harness.tabs.newSplit(.right)
        let edits = edit(harness, 0)
        harness.made[1].edits = edits
        edits.paneCount = 2
        harness.tabs.closeSelected()
        #expect(harness.tabs.unsavedQuestion == nil && harness.tabs.workspace.allPanes.count == 1)
    }

    @Test func `a tab that holds every pane on a document asks once for it`() {
        let harness = window(1)
        harness.tabs.newSplit(.right)
        let edits = edit(harness, 0)
        harness.made[1].edits = edits
        edits.paneCount = 2
        harness.tabs.close(item: harness.tabs.workspace.items[0].id)
        #expect(harness.tabs.unsavedQuestion?.documents.count == 1 && harness.tabs.workspace.count == 1)
        harness.tabs.answerUnsaved(.save)
        #expect(harness.tabs.workspace.isEmpty && edits.saved == 1 && harness.emptied)
    }

    @Test func `closing the other tabs asks for every document they hold, and not for the one that stays`() {
        let harness = window(3)
        let kept = edit(harness, 0, "kept.md")
        let one = edit(harness, 1, "one.md")
        let two = edit(harness, 2, "two.md")
        harness.tabs.closeOthers(than: harness.tabs.workspace.items[0].id)
        #expect(harness.tabs.unsavedQuestion?.documents.map(\.title) == ["one.md", "two.md"])
        harness.tabs.answerUnsaved(.save)
        #expect(harness.tabs.workspace.count == 1 && one.saved == 1 && two.saved == 1 && kept.saved == 0)
    }

    @Test func `a running command is confirmed first, then the edits are asked about`() {
        let harness = window(1)
        harness.tabs.newSplit(.right)
        harness.made[0].closeWarning = "make is running"
        _ = edit(harness, 1)
        let item = harness.tabs.workspace.items[0].id
        harness.tabs.close(item: item)
        #expect(harness.tabs.isCloseArmed(item) && harness.tabs.unsavedQuestion == nil)
        harness.tabs.close(item: item)
        #expect(harness.tabs.unsavedQuestion != nil && harness.tabs.workspace.count == 1)
    }

    @Test func `closing the window asks for what its tabs alone hold, then goes`() {
        let harness = window(2)
        let edits = edit(harness, 0)
        let shared = edit(harness, 1, "elsewhere.md")
        shared.paneCount = 2
        var closed = 0
        harness.tabs.closeWindow { closed += 1 }
        #expect(closed == 0 && harness.tabs.unsavedQuestion?.documents.map(\.title) == ["notes.md"])
        harness.tabs.answerUnsaved(.discard)
        #expect(closed == 1 && edits.discarded == 1 && shared.discarded == 0)
        edits.isEdited = false
        harness.tabs.closeWindow { closed += 1 }
        #expect(closed == 2 && harness.tabs.unsavedQuestion == nil, "with nothing to lose it goes at once")
    }

    @Test func `a kept entry asks the same when it is unloaded`() throws {
        let harness = window(2)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let id = try #require(harness.tabs.workspace.selectedEntry)
        let content = try #require(harness.tabs.shownPane.flatMap(harness.content))
        let edits = FakeEdits("kept.md")
        content.edits = edits
        harness.tabs.unload(entry: id)
        #expect(harness.tabs.unsavedQuestion != nil && !content.stopped)
        harness.tabs.answerUnsaved(.save)
        #expect(content.stopped && edits.saved == 1 && harness.tabs.favorites.favorites.entry(id)?.isOpen == false)
    }
}
