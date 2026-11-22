import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A new empty page is asked where to go by the action that makes it (the command bar), not by its view.
@MainActor @Suite("A new empty page")
struct NewBlankPageTests {
    @Test func `a new empty page opens the command bar for it; a page with an address does not`() {
        let harness = TabsHarness()
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://example.org/"]))
        #expect(harness.tabs.bar == nil)
        harness.tabs.newTab(PaneDescriptor(kind: "web"))
        #expect(harness.tabs.bar?.forNewPage == true)
    }
}
