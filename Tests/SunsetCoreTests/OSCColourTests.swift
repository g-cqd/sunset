import Testing

@testable import SunsetCore

@Suite("OSC: colours") struct OSCColourTests {
    @Test func `OSC 4 queries a palette entry in the form of the query's terminator`() {
        #expect(run("\(esc)]4;1;?\(bel)").1 == "\(esc)]4;1;rgb:cdcd/0000/0000\(bel)")
        #expect(run("\(esc)]4;1;?\(st)").1 == "\(esc)]4;1;rgb:cdcd/0000/0000\(st)")
        #expect(run("\(esc)]4;255;?\(bel)").1 == "\(esc)]4;255;rgb:eeee/eeee/eeee\(bel)")
        #expect(run("\(esc)]4;16;?\(bel)").1 == "\(esc)]4;16;rgb:0000/0000/0000\(bel)")
        #expect(run("\(esc)]4;196;?\(bel)").1 == "\(esc)]4;196;rgb:ffff/0000/0000\(bel)")
    }

    @Test func `OSC 4 sets entries from the X colour forms`() {
        #expect(run("\(esc)]4;1;rgb:ff/00/00\(bel)\(esc)]4;1;?\(bel)").1 == "\(esc)]4;1;rgb:ffff/0000/0000\(bel)")
        #expect(run("\(esc)]4;2;#0f0\(bel)").0.palette.colors[2] == RGB(0, 255, 0))
        #expect(run("\(esc)]4;2;#102030\(bel)").0.palette.colors[2] == RGB(0x10, 0x20, 0x30))
        #expect(run("\(esc)]4;2;#101020203030\(bel)").0.palette.colors[2] == RGB(0x10, 0x20, 0x30))
        #expect(run("\(esc)]4;2;rgb:1/2/3\(bel)").0.palette.colors[2] == RGB(0x11, 0x22, 0x33))
        #expect(run("\(esc)]4;2;rgb:1234/5678/9abc\(bel)").0.palette.colors[2] == RGB(0x12, 0x56, 0x9A))
        // Wider components keep their high eight bits (no rounding up).
        #expect(run("\(esc)]4;2;rgb:80ff/fffe/1\(bel)").0.palette.colors[2] == RGB(0x80, 0xFF, 0x11))
        #expect(run("\(esc)]4;2;#abc\(bel)").0.palette.colors[2] == RGB(0xAA, 0xBB, 0xCC))
        #expect(run("\(esc)]4;2;#abcdefabc\(bel)").0.palette.colors[2] == RGB(0xAB, 0xDE, 0xAB))
    }

    @Test func `several entries in one sequence answer in order`() {
        #expect(
            run("\(esc)]4;1;?;2;?\(bel)").1 == "\(esc)]4;1;rgb:cdcd/0000/0000\(bel)\(esc)]4;2;rgb:0000/cdcd/0000\(bel)"
        )
    }

    @Test func `bad colours and bad indices change nothing and answer nothing`() {
        let (screen, replies) = run(
            "\(esc)]4;1;notacolor\(bel)\(esc)]4;256;#fff\(bel)\(esc)]4;x;#fff\(bel)\(esc)]4;1;rgb:g/0/0\(bel)"
        )
        #expect(screen.palette == Palette())
        #expect(replies == "")
    }

    @Test func `OSC 104 resets entries`() {
        #expect(run("\(esc)]4;1;#fff\(bel)\(esc)]104;1\(bel)").0.palette == Palette())
        #expect(run("\(esc)]4;1;#fff\(bel)\(esc)]4;2;#fff\(bel)\(esc)]104\(bel)").0.palette == Palette())
        let (screen, _) = run("\(esc)]4;1;#fff\(bel)\(esc)]4;2;#fff\(bel)\(esc)]104;1\(bel)")
        #expect(screen.palette.colors[2] == RGB(255, 255, 255))
        #expect(screen.palette.colors[1] == Palette().colors[1])
    }

    @Test func `default foreground, background and cursor colours`() {
        #expect(run("\(esc)]10;?\(bel)").1 == "\(esc)]10;rgb:e5e5/e5e5/e5e5\(bel)")
        #expect(run("\(esc)]11;?\(st)").1 == "\(esc)]11;rgb:0000/0000/0000\(st)")
        #expect(run("\(esc)]12;?\(bel)").1 == "\(esc)]12;rgb:e5e5/e5e5/e5e5\(bel)")
        #expect(run("\(esc)]11;#102030\(bel)").0.palette.background == RGB(0x10, 0x20, 0x30))
        #expect(run("\(esc)]10;#102030\(bel)").0.palette.foreground == RGB(0x10, 0x20, 0x30))
        #expect(run("\(esc)]12;#102030\(bel)").0.palette.cursor == RGB(0x10, 0x20, 0x30))
    }

    @Test func `chained dynamic colours continue with the next one`() {
        #expect(
            run("\(esc)]10;?;?\(bel)").1 == "\(esc)]10;rgb:e5e5/e5e5/e5e5\(bel)\(esc)]11;rgb:0000/0000/0000\(bel)"
        )
        #expect(run("\(esc)]10;#111111;#222222\(bel)").0.palette.background == RGB(0x22, 0x22, 0x22))
    }

    @Test func `OSC 110, 111 and 112 reset the dynamic colours`() {
        let (screen, _) = run(
            "\(esc)]10;#111111\(bel)\(esc)]11;#222222\(bel)\(esc)]12;#333333\(bel)\(esc)]110\(bel)\(esc)]111\(bel)\(esc)]112\(bel)"
        )
        #expect(screen.palette == Palette())
    }

    @Test func `a host theme is what resets return to`() {
        var colors = Palette().colors
        colors[1] = RGB(1, 2, 3)
        var terminal = Terminal(
            columns: 10,
            rows: 4,
            palette: Palette(colors: colors, foreground: RGB(9, 9, 9), background: RGB(8, 8, 8), cursor: RGB(7, 7, 7))
        )
        terminal.feed("\(esc)]4;1;#fff\(bel)\(esc)]104;1\(bel)\(esc)]11;#000000\(bel)\(esc)]111\(bel)")
        #expect(terminal.screen.palette.colors[1] == RGB(1, 2, 3))
        #expect(terminal.screen.palette.background == RGB(8, 8, 8))
    }

    @Test func `unknown and unsafe OSC codes are ignored without a reply`() {
        let (screen, replies) = run("\(esc)]52;c;?\(bel)\(esc)]52;c;aGk=\(bel)\(esc)]9999;x\(bel)\(esc)]\(bel)")
        #expect(replies == "")
        #expect(screen.palette == Palette())
    }
}
