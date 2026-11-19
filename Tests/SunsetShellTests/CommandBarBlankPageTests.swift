import SunsetPane
import Testing

@testable import SunsetShell

/// The owner's note n52: on an empty tab, a click in the address field (the command bar) brought the page's own address bar
/// out too. The bar opened over an empty page tells it the bar takes its address.
@MainActor @Suite("The command bar over an empty page")
struct CommandBarBlankPageTests {
    @Test func `opening the bar over an empty page leaves its address to the bar; over a page with one, not`() throws {
        let harness = TabsHarness()
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://example.org/"]))
        harness.tabs.bar = nil
        let page = try #require(harness.made.last)
        harness.tabs.toggleBar()
        #expect(!page.leftAddressToBar)
        harness.tabs.bar = nil
        let blank = FakeContent(PaneDescriptor(kind: "web"))
        harness.tabs.newTab(PaneDescriptor(kind: "web", state: ["url": "https://example.com/"]))
        let pane = try #require(harness.tabs.shownPane)
        harness.tabs.register(blank, as: pane)
        harness.tabs.bar = nil
        harness.tabs.toggleBar()
        #expect(blank.leftAddressToBar)
    }
}
