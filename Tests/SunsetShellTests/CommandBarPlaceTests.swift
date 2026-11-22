import CoreGraphics
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "when in a tab … the big window-centered or pane-content-centered command bar, because sticking to the sidebar one is
/// really not convenient to write long addresses". The sidebar's field opens the bar in its place only when no tab is
/// shown.
@MainActor
@Suite("Where the command bar opens")
struct CommandBarPlaceTests {
    @Test func `with a tab shown the bar opens over the panes, not in the sidebar's field`() {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.sidebarField = CGRect(x: 0, y: 0, width: 200, height: 32)
        tabs.newTab()
        tabs.toggleBar()
        #expect(tabs.bar?.inSidebar == false)
    }
}
