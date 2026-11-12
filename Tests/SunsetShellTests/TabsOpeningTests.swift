import SunsetPane
import Testing

@testable import SunsetShell

@MainActor @Suite("Content opened by other content") struct TabsOpeningTests {
    @Test func `a tab after its opener's, not shown`() throws {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        harness.tabs.select(item: harness.tabs.workspace.items[0].id)
        let opener = try #require(harness.made.first)
        let opened = FakeContent()
        harness.tabs.insertTab(opened, after: opener, show: false)
        #expect(harness.tabs.workspace.count == 3 && harness.tabs.workspace.selectedIndex == 0)
        #expect(harness.tabs.pane(of: opened) == harness.tabs.workspace.items[1].focused)
        #expect(!opened.visible)
    }

    @Test func `a split beside its opener, with the keyboard; in a kept entry, in the entry`() throws {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        let opener = try #require(harness.made.last)
        let opened = FakeContent()
        harness.tabs.split(.right, with: opened, beside: opener)
        #expect(harness.tabs.workspace.items[1].panes.count == 2 && opened.focused)
        harness.tabs.keep(item: harness.tabs.workspace.items[1].id)
        let another = FakeContent()
        harness.tabs.split(.bottom, with: another, beside: opened)
        #expect(harness.tabs.shownItem?.panes.count == 3 && harness.tabs.workspace.count == 1)
    }

    @Test func `an opener that is nowhere gives a tab after the selected one, shown`() {
        let harness = TabsHarness()
        harness.tabs.newTab()
        let opened = FakeContent()
        harness.tabs.split(.right, with: opened, beside: FakeContent())
        #expect(harness.tabs.workspace.count == 2 && harness.tabs.workspace.selectedIndex == 1)
    }
}
