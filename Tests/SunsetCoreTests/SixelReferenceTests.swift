import Testing

@testable import SunsetCore

/// Sixel as xterm does it (graphics_sixel.c and graphics.c, xterm-snapshots patch 412, read 2026-11-26), with foot's
/// sixel.c as a second reference where the two agree: the cursor after an image, which sixels size an image, the
/// background of an opaque image (colour register 0), and DEC's HLS hues.
@Suite("Sixel, as xterm does it") struct SixelReferenceTests {
    private func terminal(columns: Int = 20, rows: Int = 8) -> Terminal {
        var t = Terminal(columns: columns, rows: rows)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    private func image(_ t: Terminal) throws -> TerminalImage {
        let placed = try #require(t.screen.graphics.placements.last)
        return try #require(t.screen.graphics.images[placed.image])
    }

    private func pixel(_ image: TerminalImage, _ x: Int, _ y: Int) -> [UInt8] {
        let offset = (y * image.width + x) * 4
        return Array(image.pixels[offset ..< offset + 4])
    }

    /// xterm's finished_parsing: the cursor goes to the text row of the image's last pixel row, at the image's first
    /// column (sixel scrolling on, mode 8452 off); foot's default is the same.
    @Test func `the cursor ends on the image's last text row, at the image's first column`() {
        var t = terminal()
        // 30 x 45 pixels at row 3, column 5 (1-based): 3 columns, 3 rows of 20-pixel cells.
        t.feed("\(esc)[3;5H\(esc)Pq\"1;1;30;45#1;2;100;0;0!30~\(esc)\\")
        #expect(t.screen.cursorRow == 4 && t.screen.cursorColumn == 4)

        // One row tall: the cursor stays on the image's row.
        var one = terminal()
        one.feed("ab\(esc)Pq#1;2;100;0;0!8~\(esc)\\")
        #expect(one.screen.cursorRow == 0 && one.screen.cursorColumn == 2)
    }

    @Test func `an image past the bottom scrolls, and the cursor is on the last row`() throws {
        var t = terminal(rows: 4)
        t.feed("\(esc)[4;3H\(esc)Pq\"1;1;10;60!10~\(esc)\\")
        #expect(t.screen.cursorRow == 3 && t.screen.cursorColumn == 2)
        let placed = try #require(t.screen.graphics.placements.first)
        #expect(placed.rows == 3 && placed.column == 2)
    }

    /// xterm's set_sixel grows the image only for the pixels a sixel sets: blank sixels (`?`) move the column, as a
    /// repeat of them does, but neither widen nor deepen it; a raster's declared size still counts.
    @Test func `blank sixels neither widen nor deepen an image`() throws {
        var wide = terminal()
        wide.feed("\(esc)P0;1q#1;2;100;0;0~??!5?\(esc)\\")
        #expect(try image(wide).width == 1 && image(wide).height == 6)

        var partial = terminal()
        partial.feed("\(esc)P0;1q#1;2;100;0;0B?\(esc)\\")
        #expect(try image(partial).height == 2, "B sets the second pixel only: two rows, not six")

        var declared = terminal()
        declared.feed("\(esc)P0;1q\"1;1;3;2#1;2;100;0;0A??\(esc)\\")
        #expect(try image(declared).width == 3 && image(declared).height == 2)
    }

    /// xterm's init_sixel_background and foot's sixel_init: an opaque image (P2 other than 1) fills what it does not
    /// draw with colour register 0, black unless the image redefines it; a transparent one (P2 = 1) leaves it clear.
    @Test func `an opaque image's background is colour register 0, not the terminal's`() throws {
        var t = terminal()
        t.feed("\(esc)[107m\(esc)Pq\"1;1;2;6#1;2;100;0;0~\(esc)\\")
        #expect(pixel(try image(t), 0, 0) == [255, 0, 0, 255])
        #expect(pixel(try image(t), 1, 0) == [0, 0, 0, 255], "register 0's default, black")

        var redefined = terminal()
        redefined.feed("\(esc)P0;0q\"1;1;2;6#0;2;0;0;100#1;2;100;0;0~\(esc)\\")
        #expect(pixel(try image(redefined), 1, 3) == [0, 0, 255, 255])

        var clear = terminal()
        clear.feed("\(esc)P0;1q\"1;1;2;6#1;2;100;0;0~\(esc)\\")
        #expect(pixel(try image(clear), 1, 0)[3] == 0)
    }

    /// xterm's hls2rgb (hue 0 blue, 120 red, 240 green; lightness and saturation in percent), scaled to 8 bits.
    @Test(arguments: [
        (0, 50, 100, RGB(0, 0, 255)), (120, 50, 100, RGB(255, 0, 0)), (240, 50, 100, RGB(0, 255, 0)),
        (60, 50, 100, RGB(255, 0, 255)), (180, 50, 100, RGB(255, 255, 0)), (300, 50, 100, RGB(0, 255, 255)),
        (360, 50, 100, RGB(0, 0, 255)), (77, 100, 40, RGB(255, 255, 255)), (200, 0, 70, RGB(0, 0, 0)),
        (90, 40, 0, RGB(102, 102, 102))
    ])
    func `DEC HLS hues land on xterm's primaries`(hue: Int, lightness: Int, saturation: Int, expected: RGB) {
        #expect(SixelDecoder.hlsToRGB(hue: hue, lightness: lightness, saturation: saturation) == expected)
    }
}
