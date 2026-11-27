import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A content that asks to be seen (a page's notification clicked): the window that holds it shows its tab, or its kept
/// entry, with the keyboard in its pane.
@MainActor
@Suite("Showing a content's tab")
struct TabsRevealTests {
    @Test func `a content in a tab of the window is shown, its pane focused`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        let first = try #require(harness.made.last)
        tabs.newTab()
        #expect(tabs.selectedContent !== first)
        #expect(tabs.reveal(first))
        #expect(tabs.selectedContent === first && first.focused)
    }

    @Test func `a content of a kept entry is shown as the entry; one held elsewhere is not found`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        let grid = FavoritesModel()
        tabs.pinned = grid
        tabs.newTab()
        let kept = try #require(harness.made.last)
        let id = try #require(tabs.workspace.selectedID)
        let entry = try #require(tabs.keep(item: id, show: false))
        tabs.newTab()
        let pinnedFirst = try #require(harness.made.last)
        let pinTab = try #require(tabs.workspace.selectedID)
        let pinEntry = try #require(tabs.pin(item: pinTab, show: true))
        tabs.newSplit(.right)
        let pinnedSecond = try #require(harness.made.last)
        tabs.newTab()
        #expect(tabs.reveal(kept) && tabs.shownEntry?.id == entry && kept.focused)
        #expect(
            tabs.reveal(pinnedFirst) && tabs.shownEntry?.id == pinEntry && tabs.selectedContent === pinnedFirst
                && pinnedFirst.focused
        )
        #expect(
            tabs.reveal(pinnedSecond) && tabs.shownEntry?.id == pinEntry && tabs.selectedContent === pinnedSecond
                && pinnedSecond.focused
        )
        #expect(!tabs.reveal(FakeContent()))
    }
}
