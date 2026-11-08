import Testing

@testable import SunsetCore

@Suite("Default cursor style") struct ScreenDefaultCursorTests {
    private let esc = "\u{1B}"

    private func configured(_ shape: CursorShape, blinks: Bool) -> Terminal {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.setDefaultCursor(shape: shape, blinks: blinks)
        return terminal
    }

    @Test func `a terminal starts with the block that blinks, until the host says otherwise`() {
        let terminal = Terminal(columns: 10, rows: 3)
        #expect(terminal.screen.cursorShape == .block && terminal.screen.cursorBlinks)
    }

    @Test func `setting the default changes the cursor now, as the program has not chosen`() {
        let terminal = configured(.bar, blinks: false)
        #expect(terminal.screen.cursorShape == .bar && !terminal.screen.cursorBlinks)
    }

    @Test func `a program's own choice wins until it asks for the default (DECSCUSR 0) or resets`() {
        var terminal = configured(.underline, blinks: false)
        terminal.feed("\(esc)[2 q")
        #expect(terminal.screen.cursorShape == .block && !terminal.screen.cursorBlinks)
        terminal.feed("\(esc)[0 q")
        #expect(
            terminal.screen.cursorShape == .underline && !terminal.screen.cursorBlinks,
            "0 means the user's default"
        )
        terminal.feed("\(esc)[5 q")
        #expect(terminal.screen.cursorShape == .bar && terminal.screen.cursorBlinks)
        terminal.feed("\(esc)[!p")
        #expect(terminal.screen.cursorShape == .underline && !terminal.screen.cursorBlinks, "a soft reset")
        terminal.feed("\(esc)[6 q\(esc)c")
        #expect(terminal.screen.cursorShape == .underline && !terminal.screen.cursorBlinks, "a full reset")
    }

    @Test func `DECSCUSR 1 and 2 stay a blinking and a steady block whatever the default is`() {
        var terminal = configured(.bar, blinks: false)
        terminal.feed("\(esc)[1 q")
        #expect(terminal.screen.cursorShape == .block && terminal.screen.cursorBlinks)
    }

    @Test func `a change of the default after the program chose does not undo the program's choice`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.feed("\(esc)[4 q")
        terminal.setDefaultCursor(shape: .bar, blinks: true)
        #expect(terminal.screen.cursorShape == .underline && !terminal.screen.cursorBlinks)
        terminal.feed("\(esc)[0 q")
        #expect(terminal.screen.cursorShape == .bar && terminal.screen.cursorBlinks)
    }
}
