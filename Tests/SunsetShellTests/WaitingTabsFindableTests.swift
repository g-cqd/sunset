import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A restored tab that waits has no content: the command bar still finds it by what it was, and its row still names it.
@MainActor @Suite("Tabs that wait are still found and named")
struct WaitingTabsFindableTests {
    private func waiting(_ descriptors: [PaneDescriptor]) -> (SpaceHarness, TabsModel) {
        let before = SpaceHarness()
        let window = before.window()
        for descriptor in descriptors { window.newTab(descriptor) }
        let saved = before.space.saved()
        let harness = SpaceHarness()
        harness.space.restore(saved)
        let back = harness.window()
        back.select(item: back.workspace.items.last?.id ?? Workspace.ItemID())
        return (harness, back)
    }

    @Test func `the bar finds a tab that is not loaded by its directory, its page, its file`() {
        let page = PaneDescriptor(kind: "web", state: ["url": "https://docs.example.org/guide", "title": "The Guide"])
        let (harness, window) = waiting([
            .terminal(directory: "/home/dev/projects/atlas"), page,
            .document(file: "/tmp/notes/plan.md"), .terminal(directory: "/x")
        ])
        #expect(harness.made.count == 1, "only the shown one is made")
        func found(_ query: String) -> Int {
            var bar = CommandBar(purpose: .search)
            bar.query = query
            return window.barResults(bar).count
        }
        #expect(found("atlas") == 1)
        #expect(found("guide") == 1)
        #expect(found("docs.example") == 1)
        #expect(found("plan.md") == 1)
    }

    @Test func `a document not loaded is named by its file, not by its kind`() {
        let title = TabLabel.title(of: .document(file: "/tmp/notes/plan.md"))
        #expect(title == "plan.md")
    }
}
