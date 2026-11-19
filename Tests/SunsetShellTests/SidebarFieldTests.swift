import CoreGraphics
import SunsetMetrics
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner, 2026-11-17 (roadmap 0035 G): "Address bar in the sidebar should always be there and be used as a central place
/// where to start a search or creating a tab when focused on a terminal tab. its dimensions should match ones of a regular
/// tab". His answer: the command bar's results are listed under it.
@MainActor
@Suite("The sidebar's field")
struct SidebarFieldTests {
    @Test func `the field is as tall as a tab's row and leaves the rows the same gap as between two rows`() {
        let sidebar = TabSidebar(tabs: TabsModel(), settings: ShellSettings(), accessory: nil) {}
        let row = Design.oneLineHeight(sidebar.layout, height: Design.Size.tabRow)
        #expect(sidebar.accessoryHeight == row)
    }

    @Test func `the command bar opens in the sidebar's field while there is one, else over the panes`() {
        let tabs = TabsModel()
        tabs.toggleBar()
        #expect(tabs.bar?.inSidebar == false)
        tabs.toggleBar()
        tabs.sidebarField = CGRect(x: 10, y: 40, width: 220, height: 32)
        tabs.toggleBar()
        #expect(tabs.bar?.inSidebar == true && tabs.bar?.purpose == .search)
        tabs.toggleBar()
        #expect(tabs.bar == nil)
    }
}
