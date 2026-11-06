import SunsetCore
import Testing

@testable import SunsetRender

private let esc = "\u{1B}"
private let metrics = RenderMetrics(cellWidth: 8, cellHeight: 16)
private let black = RGB(0, 0, 0)
private let white = RGB(229, 229, 229)

/// A terminal, a renderer with box glyphs and a surface the size of the grid.
private struct Rig {
    var terminal: Terminal
    var surface: Surface
    let renderer: CPURenderer

    init(
        _ columns: Int = 10,
        _ rows: Int = 4,
        glyphs: any GlyphSource = BoxGlyphSource(),
        metrics: RenderMetrics = metrics
    ) {
        terminal = Terminal(columns: columns, rows: rows)
        let size = metrics.surfaceSize(columns: columns, rows: rows)
        surface = Surface(width: size.width, height: size.height)
        renderer = CPURenderer(metrics: metrics, glyphs: glyphs)
    }

    /// Feeds text and draws a frame (and clears the dirty marks, as a host does).
    mutating func frame(_ text: String = "", cursorVisible: Bool = true) {
        terminal.feed(text)
        renderer.render(terminal.screen, into: &surface, cursorVisible: cursorVisible)
        terminal.clearDirty()
    }

    /// The colour at a pixel inside the cell (row, column).
    func pixel(row: Int, column: Int, x: Int, y: Int) -> RGB {
        surface[column * metrics.cellWidth + x, row * metrics.cellHeight + y]
    }
}

/// Records what the renderer asks for.
private final class Recorder: GlyphSource {
    nonisolated(unsafe) var requests: [String] = []
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        requests.append("\(text)|\(bold ? "b" : "")\(italic ? "i" : "")|\(columns)")
        return BoxGlyphSource().glyph(for: text, bold: bold, italic: italic, columns: columns, metrics: metrics)
    }
}

@Suite("CPU renderer") struct CPURendererTests {
    @Test func `an empty screen is the default background`() {
        var rig = Rig()
        rig.frame(cursorVisible: false)
        #expect(rig.surface.width == 80 && rig.surface.height == 64)
        #expect(rig.surface.pixels.allSatisfy { $0 == Surface.pack(black) })
    }

    @Test func `a character is a glyph in the foreground colour inside its cell`() {
        var rig = Rig()
        rig.frame("a", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
        #expect(rig.pixel(row: 0, column: 0, x: 7, y: 15) == black)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == black)
    }

    @Test func `a space draws no glyph`() {
        var rig = Rig()
        rig.frame(" ", cursorVisible: false)
        #expect(rig.surface.pixels.allSatisfy { $0 == Surface.pack(black) })
    }

    @Test func `colours come from the palette, the 256 colours and true colour`() {
        var rig = Rig()
        rig.frame("\(esc)[31;44mx\(esc)[38;5;200my\(esc)[38;2;1;2;3;48;2;9;8;7mz", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == RGB(205, 0, 0))
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == RGB(0, 0, 238))
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == Palette().colors[200])
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == RGB(1, 2, 3))
        #expect(rig.pixel(row: 0, column: 2, x: 0, y: 0) == RGB(9, 8, 7))
    }

    @Test func `inverse swaps, faint dims, invisible hides`() {
        var rig = Rig()
        rig.frame("\(esc)[7mi\(esc)[0;2mf\(esc)[0;8mh", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == black)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == RGB(114, 114, 114))
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == black)
    }

    @Test func `a double-width character spans two cells and its second half draws nothing of its own`() {
        let recorder = Recorder()
        var rig = Rig(glyphs: recorder)
        rig.frame("日", cursorVisible: false)
        #expect(recorder.requests == ["日||2"])
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 3, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 5, y: 5) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 6, y: 5) == black)
        #expect(rig.pixel(row: 0, column: 2, x: 3, y: 5) == black)
    }

    @Test func `a cluster is asked for whole, a glyph once per distinct request`() {
        let recorder = Recorder()
        var rig = Rig(glyphs: recorder)
        rig.frame("e\u{301}e\u{301}\(esc)[1mx\(esc)[0mx\(esc)[1mx\(esc)[3mx", cursorVisible: false)
        #expect(recorder.requests == ["e\u{301}||1", "x|b|1", "x||1", "x|bi|1"])
    }

    @Test func `underline styles, strikethrough and overline are lines in the underline colour`() {
        var rig = Rig(10, 8)
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
        var rig = Rig()
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
        var rig = Rig()
        rig.frame("a\u{08}")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        rig.frame(cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
        rig.frame("\(esc)[?25l")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == black)
    }

    @Test func `a cursor on a double-width character covers both cells`() {
        var rig = Rig()
        rig.frame("日\(esc)[1G")
        #expect(rig.pixel(row: 0, column: 0, x: 0, y: 0) == white)
        #expect(rig.pixel(row: 0, column: 1, x: 7, y: 0) == white)
    }

    @Test func `reverse video swaps the default colours of the whole screen`() {
        var rig = Rig()
        rig.frame("a\(esc)[?5h", cursorVisible: false)
        #expect(rig.pixel(row: 3, column: 9, x: 7, y: 15) == white)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == black)
    }

    @Test func `changing the palette redraws the screen`() {
        var rig = Rig()
        rig.frame("\(esc)[31mx", cursorVisible: false)
        rig.frame("\(esc)]4;1;#00ff00\u{7}")
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 5) == RGB(0, 255, 0))
    }

    @Test func `padding surrounds the grid in the background colour`() {
        var padded = metrics
        padded.paddingX = 3
        padded.paddingY = 5
        var rig = Rig(10, 4, metrics: padded)
        rig.frame("\(esc)[44mx", cursorVisible: false)
        #expect(rig.surface.width == 86 && rig.surface.height == 74)
        #expect(rig.surface[0, 0] == black)
        #expect(rig.surface[3, 5] == RGB(0, 0, 238))
        #expect(rig.surface[2, 5] == black)
    }
}

@Suite("PNG") struct PNGTests {
    @Test func `known checksums`() {
        #expect(PNG.crc32(Array("123456789".utf8)) == 0xCBF4_3926)
        #expect(PNG.adler32(Array("Wikipedia".utf8)) == 0x11E6_0398)
    }

    @Test func `a surface becomes a well-formed PNG`() {
        var surface = Surface(width: 3, height: 2)
        surface.pixels[0] = 0xFF00_00FF  // red
        let bytes = PNG.encode(surface)
        #expect(Array(bytes.prefix(8)) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        // IHDR: length 13, type, width 3, height 2, 8-bit RGBA.
        #expect(Array(bytes[8 ..< 16]) == [0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52])
        #expect(Array(bytes[16 ..< 24]) == [0, 0, 0, 3, 0, 0, 0, 2])
        #expect(Array(bytes[24 ..< 29]) == [8, 6, 0, 0, 0])
        #expect(Array(bytes.suffix(12)) == [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82])
        // The IDAT payload: zlib header, one stored block holding 2 rows of (1 + 12) bytes, whose first pixel is red.
        let idat = 33 + 8
        #expect(Array(bytes[idat ..< idat + 2]) == [0x78, 0x01])
        #expect(bytes[idat + 2] == 1)
        #expect(Array(bytes[idat + 3 ..< idat + 5]) == [26, 0])
        #expect(Array(bytes[idat + 7 ..< idat + 12]) == [0, 255, 0, 0, 255])
    }
}
