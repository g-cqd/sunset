import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Command-T opens the command bar, ready to search or take an address.
@MainActor @Suite("A new empty page opens the command bar")
struct NewTabBarTests {
    @Test func `a new page with no address opens the bar; one with an address, or a terminal, does not`() {
        let harness = TabsHarness()
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: [:]))
        #expect(harness.tabs.bar?.prompt == "Search or enter an address…", "an empty page: the bar, asking where to go")
        harness.tabs.bar = nil
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://example.org/"]))
        #expect(harness.tabs.bar == nil)
        harness.tabs.newTab(.terminal(directory: nil))
        #expect(harness.tabs.bar == nil)
    }
}
