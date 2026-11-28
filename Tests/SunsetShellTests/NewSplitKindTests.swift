import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "A split makes a pane of the same kind, by a setting" (`tabs.newSplit`): Split Right and Split Down put what they are
/// given beside the focused pane, a terminal by default; a page with nowhere to go asks for its address, as a new tab's.
@MainActor
@Suite("What a new split is")
struct NewSplitKindTests {
    @Test func `a split is a terminal by default, else what it is given, beside the focused pane in the same tab`()
        throws
    {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        tabs.newSplit(.right)
        let item = try #require(tabs.workspace.selectedItem)
        #expect(item.panes.count == 2)
        #expect(
            harness.content(item.panes[1])?.descriptor.kind == "fake",
            "no descriptor: the terminal the window makes"
        )
        #expect(tabs.bar == nil)
        let page = PaneDescriptor(kind: "web", state: [:])
        tabs.newSplit(.bottom, page)
        let after = try #require(tabs.workspace.selectedItem)
        #expect(after.id == item.id && after.panes.count == 3)
        #expect(harness.made.last?.descriptor.kind == "web")
        #expect(tabs.bar?.forNewPage == true, "a blank page asks for its address")
    }

    @Test func `a kind that is off is not made: the bar asks which tab goes beside`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let made = harness.made.count
        tabs.scopes = Scopes(web: false)
        tabs.newSplit(.right, PaneDescriptor(kind: "web", state: [:]))
        #expect(harness.made.count == made && tabs.workspace.selectedItem?.panes.count == 1)
        #expect(tabs.bar != nil)
    }
}
