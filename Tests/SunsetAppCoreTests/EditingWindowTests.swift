import Testing

@testable import SunsetAppCore

/// The window whose pane the Format menu edits (⌘B, ⌘I, ⌘K, ⇧⌘K, ⇧⌘X): the key window when it is a tab window, and none
/// otherwise. A key typed in a web pop-up, a sheet or the Passwords setup is that window's, never an edit of a document in
/// the window behind it.
@Suite("Format menu: the window it edits") struct EditingWindowTests {
    final class Window {
        let isTabWindow: Bool

        init(tabs: Bool) {
            isTabWindow = tabs
        }
    }

    private func editing(key: Window?) -> Window? {
        EditingWindow.target(key: key) { $0.isTabWindow }
    }

    @Test func `the key tab window is the one edited`() {
        let tabs = Window(tabs: true)
        #expect(editing(key: tabs) === tabs)
    }

    @Test func `a pop-up, a sheet, or no key window at all edit nothing`() {
        #expect(editing(key: Window(tabs: false)) == nil)
        #expect(editing(key: nil) == nil)
    }
}
