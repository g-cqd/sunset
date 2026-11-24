import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A tab of the window's list, a document's included, can be unloaded by hand: it stays in the list, drawn as not loaded, and is
/// made again from where it was when shown.
@MainActor @Suite("Unloading a tab of the list")
struct UnloadingATabTests {
    private let document = PaneDescriptor.document(file: "/tmp/notes.md")

    @Test func `a tab no window shows lets go of its content and waits; shown, it is made again`() throws {
        let harness = SpaceHarness()
        let window = harness.window()
        window.newTab(document)
        window.newTab(.terminal(directory: "/b"))
        let (other, shown) = (window.workspace.items[0], window.workspace.items[1])
        let content = try #require(window.content(other.focused))

        #expect(window.canUnload(item: other.id), "a document that is not on screen")
        #expect(!window.canUnload(item: shown.id))
        #expect(!window.unload(item: shown.id), "the tab on screen stays")
        #expect(window.unload(item: other.id))
        #expect(content is FakeContent && (content as? FakeContent)?.stopped == true)
        #expect(window.content(other.focused) == nil && window.workspace.count == 2)
        #expect(window.pendingDescriptor(other.focused) == document, "what it starts from")
        #expect(harness.space.saved().contents[other.focused] == document, "still in the session")

        window.select(item: other.id)
        #expect(window.content(other.focused)?.descriptor == document)
    }
}
