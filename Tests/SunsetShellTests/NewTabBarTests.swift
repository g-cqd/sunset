import SunsetPane
import Testing

@testable import SunsetShell

/// The owner's note n12 (2026-11-18): "when hitting cmd t and basically creating a new tab (web here i guess) the big command
/// bar should be focused to let the user directly search or input the link".
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
