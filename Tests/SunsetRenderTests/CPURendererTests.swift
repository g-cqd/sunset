import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer") struct CPURendererTests {
    @Test func `an empty screen is the default background`() {
        var rig = CPURendererRig()
        rig.frame(cursorVisible: false)
        #expect(rig.surface.width == 80 && rig.surface.height == 64)
        #expect(rig.surface.pixels.allSatisfy { $0 == Surface.pack(black) })
    }

    @Test func `a character is a glyph in the foreground colour inside its cell`() {
        var rig = CPURendererRig()
        rig.frame("a", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
        #expect(rig.pixel(row: 0, column: 0, x: 7, y: 15) == black)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == black)
    }

    @Test func `a space draws no glyph`() {
        var rig = CPURendererRig()
        rig.frame(" ", cursorVisible: false)
        #expect(rig.surface.pixels.allSatisfy { $0 == Surface.pack(black) })
    }

    @Test func `colours come from the palette, the 256 colours and true colour`() {
        var rig = CPURendererRig()
        rig.frame("\(esc)[31;44mx\(esc)[38;5;200my\(esc)[38;2;1;2;3;48;2;9;8;7mz", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == RGB(205, 0, 0))
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == RGB(0, 0, 238))
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == Palette().colors[200])
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == RGB(1, 2, 3))
        #expect(rig.pixel(row: 0, column: 2, x: 0, y: 0) == RGB(9, 8, 7))
    }

    @Test func `inverse swaps, faint dims, invisible hides`() {
        var rig = CPURendererRig()
        rig.frame("\(esc)[7mi\(esc)[0;2mf\(esc)[0;8mh", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == black)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == RGB(114, 114, 114))
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == black)
    }

    @Test func `a double-width character spans two cells and its second half draws nothing of its own`() {
        let recorder = RecordingGlyphSource()
        var rig = CPURendererRig(glyphs: recorder)
        rig.frame("日", cursorVisible: false)
        #expect(recorder.requests == ["日||2"])
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 5, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 6, y: 5) == black)
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == black)
    }

    @Test func `a cluster is asked for whole, a glyph once per distinct request`() {
        let recorder = RecordingGlyphSource()
        var rig = CPURendererRig(glyphs: recorder)
        rig.frame("e\u{301}e\u{301}\(esc)[1mx\(esc)[0mx\(esc)[1mx\(esc)[3mx", cursorVisible: false)
        #expect(recorder.requests == ["e\u{301}||1", "x|b|1", "x||1", "x|bi|1"])
    }

    @Test func `underline styles, strikethrough and overline are lines in the underline colour`() {
        var rig = CPURendererRig(10, 8)
        rig.frame(
            "\(esc)[4;58;2;1;2;3m \(esc)[0;21m \(esc)[0;9;31m \(esc)[0;53m \(esc)[0;4:3m \(esc)[0;4:4m \(esc)[0;4:5m ",
            cursorVisible: false
        )
        let underline = metrics.underlineY
        #expect(rig.pixel(row: 0, column: 0, x: 4, y: underline) == RGB(1, 2, 3))
        #expect(rig.pixel(row: 0, column: 0, x: 4, y: underline - 1) == black)
        #expect(rig.pixel(row: 0, column: 1, x: 4, y: underline) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 4, y: underline - 2) == white)
        #expect(rig.pixel(row: 0, column: 2, x: 4, y: metrics.strikeY) == RGB(205, 0, 0))
        #expect(rig.pixel(row: 0, column: 3, x: 4, y: metrics.overlineY) == white)
        // Curly goes up and down, dotted skips every other pixel, dashed leaves a gap.
        let curly = (0 ..< 8).map { rig.pixel(row: 0, column: 4, x: $0, y: underline - 1 + [0, 1, 2, 1][$0 % 4]) }
        #expect(curly.allSatisfy { $0 == white })
        #expect(rig.pixel(row: 0, column: 5, x: 0, y: underline) == white)
        #expect(rig.pixel(row: 0, column: 5, x: 1, y: underline) == black)
        #expect(rig.pixel(row: 0, column: 6, x: 2, y: underline) == white)
        #expect(rig.pixel(row: 0, column: 6, x: 3, y: underline) == black)
    }

    @Test func `the block cursor inverts its cell, the other shapes draw a line`() {
        var rig = CPURendererRig()
        rig.frame("a\u{08}")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == black)
        rig.frame("\(esc)[3 q")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 15) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 14) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 1) == black)
        rig.frame("\(esc)[5 q")
        #expect(rig.pixel(row: 0, column: 0, x: 1, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 0) == black)
    }

    @Test func `the cursor is hidden by the host's blink phase or by the program`() {
        var rig = CPURendererRig()
        rig.frame("a\u{08}")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        rig.frame(cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
        rig.frame("\(esc)[?25l")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
    }

    @Test func `a cursor on a double-width character covers both cells`() {
        var rig = CPURendererRig()
        rig.frame("日\(esc)[1G")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 7, y: 0) == white)
    }

    @Test func `reverse video swaps the default colours of the whole screen`() {
        var rig = CPURendererRig()
        rig.frame("a\(esc)[?5h", cursorVisible: false)
        #expect(rig.pixel(row: 3, column: 9, x: 7, y: 15) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == black)
    }

    @Test func `changing the palette redraws the screen`() {
        var rig = CPURendererRig()
        rig.frame("\(esc)[31mx", cursorVisible: false)
        rig.frame("\(esc)]4;1;#00ff00\u{7}")
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == RGB(0, 255, 0))
    }

    @Test func `padding surrounds the grid in the background colour`() {
        var padded = metrics
        padded.paddingX = 3
        padded.paddingY = 5
        var rig = CPURendererRig(10, 4, metrics: padded)
        rig.frame("\(esc)[44mx", cursorVisible: false)
        #expect(rig.surface.width == 86 && rig.surface.height == 74)
        #expect(rig.surface[0, 0] == black)
        #expect(rig.surface[3, 5] == RGB(0, 0, 238))
        #expect(rig.surface[2, 5] == black)
    }

    @Test func `a private-use symbol followed by a blank takes two cells to be drawn in, not otherwise`() {
        let recorder = RecordingGlyphSource()
        var rig = CPURendererRig(glyphs: recorder)
        // Followed by spaces: drawn over two cells. Followed by a bracket: in its own cell.
        rig.frame("\u{101C5B}  passed\r\n[\u{1008A4}]", cursorVisible: false)
        #expect(recorder.requests.contains("\u{101C5B}||2"))
        #expect(recorder.requests.contains("\u{1008A4}||1"))
        #expect(!recorder.requests.contains("\u{101C5B}||1"))
    }
}
