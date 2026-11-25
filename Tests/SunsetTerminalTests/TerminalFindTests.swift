import SunsetCore
import Testing

@testable import SunsetTerminalModel

/// Terminal find controller (`TerminalFind`, T-3 / roadmap 0026): cycling next/previous with wrap, jumping viewport to
/// matches, invalid regex status, selection handoff, and clearing highlights on close.
@Suite("Terminal find state")
struct TerminalFindTests {
    @Test @MainActor func `steps through matches with wrap, jumps viewport, and clears on close`() {
        var terminal = Terminal(columns: 20, rows: 3, scrollbackLimit: 50)
        terminal.feed("hit-0\r\nline1\r\nline2\r\nline3\r\nhit-1\r\nline5\r\nhit-2")
        let screen = terminal.screen

        let find = TerminalFind()
        find.currentScreen = { screen }
        find.currentViewportFirstLine = { screen.scrollbackCount }
        find.currentViewportRows = { screen.rows }
        var jumpedTo: [Int] = []
        find.onJumpToLine = { jumpedTo.append($0) }

        find.open()
        find.text = "hit-"
        find.restart()
        #expect(find.matches.count == 3)
        #expect(find.index == 2)
        #expect(find.status == "3 of 3")
        #expect(find.highlight.current == 2)
        #expect(jumpedTo.last == find.matches[2].start.line)

        // Wrap forward from last -> first.
        find.step(backwards: false)
        #expect(find.index == 0)
        #expect(find.status == "1 of 3")
        #expect(jumpedTo.last == find.matches[0].start.line)

        // Wrap backwards from first -> last.
        find.step(backwards: true)
        #expect(find.index == 2)

        // Invalid regex reports cleanly.
        find.isRegex = true
        find.text = "[unterminated"
        find.restart()
        #expect(find.status == "Invalid regex")
        #expect(find.highlight.isEmpty)

        // Use selection resets regex mode to literal.
        find.useSelection("hit-1")
        #expect(!find.isRegex)
        #expect(find.matches.count == 1)
        #expect(find.status == "1 of 1")

        // Close clears highlights.
        find.close()
        #expect(!find.isOpen)
        #expect(find.highlight.isEmpty)
    }
}
