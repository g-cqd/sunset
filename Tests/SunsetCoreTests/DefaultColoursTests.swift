import Testing

@testable import SunsetCore

@Suite("Default colours set by the host") struct DefaultColoursTests {
    @Test func `the host sets the default foreground, background and cursor, and nil leaves one alone`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.setDefaultColors(foreground: RGB(1, 2, 3), background: RGB(4, 5, 6), cursor: nil)
        #expect(terminal.screen.palette.foreground == RGB(1, 2, 3))
        #expect(terminal.screen.palette.background == RGB(4, 5, 6))
        #expect(terminal.screen.palette.cursor == Palette().cursor)
    }

    @Test func `a program's change is undone by its reset to the host's colours, not to xterm's`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.setDefaultColors(foreground: RGB(10, 20, 30), background: RGB(40, 50, 60), cursor: RGB(70, 80, 90))
        terminal.feed("\(esc)]11;#ff0000\(bel)\(esc)]10;#00ff00\(bel)\(esc)]12;#0000ff\(bel)")
        #expect(terminal.screen.palette.background == RGB(255, 0, 0))
        terminal.feed("\(esc)]110\(bel)\(esc)]111\(bel)\(esc)]112\(bel)")
        #expect(terminal.screen.palette.foreground == RGB(10, 20, 30))
        #expect(terminal.screen.palette.background == RGB(40, 50, 60))
        #expect(terminal.screen.palette.cursor == RGB(70, 80, 90))
    }

    @Test func `the 256 palette entries are not touched, and a program's own change to one stays`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.feed("\(esc)]4;1;#123456\(bel)")
        terminal.setDefaultColors(foreground: RGB(9, 9, 9), background: nil, cursor: nil)
        #expect(terminal.screen.palette.colors[1] == RGB(0x12, 0x34, 0x56))
        #expect(terminal.screen.palette.colors[2] == Palette().colors[2])
    }

    @Test func `a screen that was marked clean is dirty again, so the renderer draws the new colours`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.clearDirty()
        terminal.setDefaultColors(foreground: nil, background: RGB(7, 7, 7), cursor: nil)
        #expect(terminal.screen.hasDirtyRows)
    }

    @Test func `the host sets the 16 ANSI colours, and a program's reset returns to them`() {
        var terminal = Terminal(columns: 10, rows: 3)
        let theme: [RGB] = (0 ..< 16)
            .map { (index: Int) -> RGB in
                RGB(UInt8(index * 10), UInt8(index * 5), UInt8(200 - index))
            }
        terminal.setAnsiColors(theme)
        #expect(Array(terminal.screen.palette.colors[0 ..< 16]) == theme)
        #expect(terminal.screen.palette.colors[16] == Palette().colors[16], "the cube and the greys are not touched")
        terminal.feed("\(esc)]4;3;#010203\(bel)")
        #expect(terminal.screen.palette.colors[3] == RGB(1, 2, 3))
        terminal.feed("\(esc)]104\(bel)")
        #expect(
            Array(terminal.screen.palette.colors[0 ..< 16]) == theme,
            "reset goes to the host's colours, not xterm's"
        )
    }

    @Test func `fewer than 16 colours set the first ones, more are ignored, and the screen is drawn again`() {
        var terminal = Terminal(columns: 10, rows: 3)
        terminal.clearDirty()
        terminal.setAnsiColors([RGB(9, 9, 9), RGB(8, 8, 8)])
        #expect(terminal.screen.palette.colors[0] == RGB(9, 9, 9) && terminal.screen.palette.colors[1] == RGB(8, 8, 8))
        #expect(terminal.screen.palette.colors[2] == Palette().colors[2])
        #expect(terminal.screen.hasDirtyRows)
        terminal.setAnsiColors((0 ..< 40).map { _ in RGB(1, 1, 1) })
        #expect(terminal.screen.palette.colors[16] == Palette().colors[16])
    }
}
