import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// Roadmap 0047 E (the owner, 2026-11-18: "when focusing on command bar using cmd L, the focused input should contain the
/// current tab target, for web tabs mostly").
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
