import Foundation
import MarkdownLookKit
import Testing

@testable import SunsetDocuments

/// A task's box on the page is the system's checkbox, and a click on it checks the task off in the text (the owner,
/// 2026-11-17: "they should render the default macos checkboxes").
@MainActor
@Suite("A task checked off from the page")
struct TaskToggleTests {
    @Test func `a click rewrites the box, after text of any width`() {
        let source = MarkdownSource(text: "# Café 🌅\n\n- [ ] open\n- [X] done\n")
        let bytes = Array(source.text.utf8)
        let first = bytes.firstIndex(of: UInt8(ascii: "[")) ?? -1
        #expect(source.toggleTask(at: first))
        #expect(source.text == "# Café 🌅\n\n- [x] open\n- [X] done\n")
        #expect(source.toggleTask(at: first + 11))
        #expect(source.text == "# Café 🌅\n\n- [x] open\n- [ ] done\n")
    }

    @Test func `undo puts the box back`() {
        let source = MarkdownSource(text: "- [ ] open\n")
        #expect(source.toggleTask(at: 2) && source.text == "- [x] open\n")
        source.undoManager.undo()
        #expect(source.text == "- [ ] open\n")
    }

    @Test func `a box that moved is left alone`() {
        let source = MarkdownSource(text: "- [ ] open\n")
        #expect(!source.toggleTask(at: 0) && !source.toggleTask(at: 9) && source.text == "- [ ] open\n")
    }
}
