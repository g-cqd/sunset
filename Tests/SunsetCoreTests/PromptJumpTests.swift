import Testing

@testable import SunsetCore

/// Going from one shell prompt to the next in the history (OSC 133 marks).
@Suite("Prompt jump") struct PromptJumpTests {
    /// Three commands of four lines each on a screen of four rows: prompts at lines 0, 4 and 8 of 13 (9 in the history).
    private func session() -> Terminal {
        var text = ""
        for command in 0 ..< 3 { text += "\u{1B}]133;A\u{7}$ run \(command)\r\nout\r\nout\r\nout\r\n" }
        return terminal(text, 20, 4)
    }

    @Test func `the previous prompt is the nearest one above the top of the window, the next the nearest below`() {
        let screen = session().screen
        #expect(screen.absoluteLineCount == 13)
        #expect(screen.promptLine(.previous, from: 9) == 8)
        #expect(screen.promptLine(.previous, from: 8) == 4)
        #expect(screen.promptLine(.previous, from: 0) == nil)
        #expect(screen.promptLine(.next, from: 0) == 4)
        #expect(screen.promptLine(.next, from: 8) == nil, "past the last prompt there is the live screen")
    }

    @Test func `a screen without marks has no prompt to go to, and marks other than a prompt's start do not count`() {
        #expect(terminal("a\r\nb\r\nc\r\nd\r\ne\r\nf", 20, 4).screen.promptLine(.previous, from: 2) == nil)
        let ended = terminal("a\r\n\u{1B}]133;D;0\u{7}b\r\nc\r\nd\r\ne\r\nf", 20, 4).screen
        #expect(ended.promptLine(.previous, from: 2) == nil)
    }

    @Test func `the window shows a line of the history at its top, and stays within the history`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 9)
        viewport.show(line: 4)
        #expect(viewport.firstLine == 4 && viewport.scrolledBack == 5)
        viewport.show(line: 12)
        #expect(viewport.isLive, "a line of the live screen is shown by the live screen")
        viewport.show(line: -3)
        #expect(viewport.firstLine == 0)
    }
}
