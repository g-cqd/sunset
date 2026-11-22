import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// Command-L opens the command bar on the tab's own target (a page's address).
@MainActor @Suite("The command bar opened on a tab")
struct CommandBarTargetTests {
    @Test func `opened on a page, its field holds the page's address; on a terminal, nothing`() {
        let harness = TabsHarness()
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://example.org/path?q=1"]))
        harness.tabs.toggleBar()
        #expect(harness.tabs.bar?.query == "https://example.org/path?q=1")
        harness.tabs.toggleBar()
        harness.tabs.newTab(PaneDescriptor(kind: PaneDescriptor.terminalKind))
        harness.tabs.toggleBar()
        #expect(harness.tabs.bar?.query == "")
    }
}
