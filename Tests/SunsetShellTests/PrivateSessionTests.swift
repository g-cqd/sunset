import SunsetPane
import Testing

@testable import SunsetShell

@Suite("What the session keeps of private pages") @MainActor struct PrivateSessionTests {
    @Test func `a private tab is left out, and a private pane of a split goes from it`() throws {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.tabs.newTab()
        harness.tabs.newSplit(.right)
        let made = harness.made
        try #require(made.count == 3)
        made[0].isPrivate = true
        made[2].isPrivate = true
        let saved = harness.tabs.savedWindow()
        #expect(saved.workspace.items.count == 1 && saved.workspace.items.allSatisfy { !$0.isSplit })
        #expect(saved.workspace.allPanes.count == 1 && saved.contents.count == 1)
        #expect(harness.tabs.workspace.allPanes.count == 3)
    }
}
