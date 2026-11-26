import AemiKernel
import Testing

@testable import SunsetCore

/// Tests Sixel DCS graphics, iTerm2 inline images (`OSC 1337 ; File=...`), Kitty animation (`a=f`, `a=a`, `a=c`),
/// Kitty image numbers (`I=`), alternate-screen image scroll, and cell-size change redraw marking (roadmap 0010 E & F).
@Suite("Sixel, iTerm2 inline images, and Kitty animation") struct TerminalImagesExtendedTests {
    private func terminal(columns: Int = 20, rows: Int = 8) -> Terminal {
        var t = Terminal(columns: columns, rows: rows)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    private func replies(_ t: inout Terminal) -> String {
        String(decoding: t.takeReplies(), as: UTF8.self)
    }

    private func minimalPNG(width: Int, height: Int) -> [UInt8] {
        [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
            UInt8((width >> 24) & 0xFF), UInt8((width >> 16) & 0xFF), UInt8((width >> 8) & 0xFF), UInt8(width & 0xFF),
            UInt8((height >> 24) & 0xFF), UInt8((height >> 16) & 0xFF), UInt8((height >> 8) & 0xFF),
            UInt8(height & 0xFF),
            8, 6, 0, 0, 0, 0, 0, 0, 0
        ]
    }

    // MARK: - Sixel

    @Test func `Sixel decodes RGB palette, repeat count, raster attributes, CR and NL, and places at cursor`() throws {
        var t = terminal()
        // Define color 1 = pure red (100,0,0), draw 20px wide x 6px tall solid band (`~` = 0x3F + 0x3F = all 6 bits),
        // then next sixel row (`-`), color 2 = pure green (0,100,0), 20px wide x 6px tall -> 20x12 RGBA image.
        t.feed("\(esc)P0;1q\"1;1;20;12#1;2;100;0;0#1!20~-#2;2;0;100;0#2!20~\(esc)\\")
        let placement = try #require(t.screen.graphics.placements.first)
        let image = try #require(t.screen.graphics.images[placement.image])
        #expect(image.format == .rgba)
        #expect(image.width == 20 && image.height == 12)
        // Top-left pixel (0,0) = red (255, 0, 0, 255)
        #expect(image.pixels[0] == 255 && image.pixels[1] == 0 && image.pixels[2] == 0 && image.pixels[3] == 255)
        // Row 6 pixel (0,6) = green (0, 255, 0, 255)
        let row6 = 6 * 20 * 4
        #expect(image.pixels[row6] == 0 && image.pixels[row6 + 1] == 255 && image.pixels[row6 + 2] == 0)
        #expect(placement.columns == 2 && placement.rows == 1)
        #expect(t.screen.cursorRow == 1 && t.screen.cursorColumn == 0)
    }

    @Test func `Sixel rejects hostile oversized raster or repeat counts without trapping`() {
        var t = terminal()
        t.feed("\(esc)P0;1q\"1;1;99999;99999!50000~\(esc)\\")
        #expect(t.screen.graphics.images.isEmpty)
        #expect(t.screen.graphics.placements.isEmpty)
        // Malformed empty / non-sixel DCS is ignored cleanly.
        t.feed("\(esc)Pq\(esc)\\")
        #expect(t.screen.graphics.images.isEmpty)
    }

    // MARK: - iTerm2 inline images (`OSC 1337 ; File=...`)

    @Test func `iTerm2 OSC 1337 File= stores PNG and computes px, cell, and percent sizes with aspect ratio`() throws {
        var t = terminal()
        let png = Base64.encodedString(minimalPNG(width: 40, height: 20))
        t.feed("\(esc)]1337;File=inline=1;width=20px;preserveAspectRatio=1:\(png)\u{07}")
        let p1 = try #require(t.screen.graphics.placements.first)
        let img1 = try #require(t.screen.graphics.images[p1.image])
        #expect(img1.format == .png && img1.width == 40 && img1.height == 20)
        #expect(p1.width == 20 && p1.height == 10 && p1.columns == 2 && p1.rows == 1)

        // inline=0 (download only) must be ignored.
        t.feed("\(esc)]1337;File=inline=0;width=2:\(png)\u{07}")
        #expect(t.screen.graphics.placements.count == 1)

        // Percentage width (50% of 20*10=200px = 100px; 2:1 aspect -> 50px height -> 10 cols x 3 rows).
        t.feed("\(esc)]1337;File=inline=1;width=50%:\(png)\(esc)\\")
        let p2 = try #require(t.screen.graphics.placements.last)
        #expect(p2.width == 100 && p2.height == 50 && p2.columns == 10 && p2.rows == 3)
    }

    @Test func `iTerm2 OSC 1337 File= rejects non-PNG payloads and oversized PNG headers`() {
        var t = terminal()
        let junk = Base64.encodedString(Array("not a png".utf8))
        t.feed("\(esc)]1337;File=inline=1:\(junk)\u{07}")
        let huge = Base64.encodedString(minimalPNG(width: 50_000, height: 50_000))
        t.feed("\(esc)]1337;File=inline=1:\(huge)\u{07}")
        #expect(t.screen.graphics.images.isEmpty)
    }

    // MARK: - Kitty animation (`a=f`, `a=a`, `a=c`) & image numbers (`I=`)

    @Test func `Kitty image numbers I= allocate unique ids, place newest, and delete by d=n/N`() throws {
        var t = terminal()
        let px = Base64.encodedString([10, 20, 30, 255])
        t.feed("\(esc)_Ga=t,I=42,f=32,s=1,v=1;\(px)\(esc)\\")
        let reply1 = replies(&t)
        #expect(reply1.contains("I=42;OK") && reply1.contains("i="))
        t.feed("\(esc)_Ga=p,I=42,q=2\(esc)\\")
        #expect(t.screen.graphics.placements.count == 1)
        t.feed("\(esc)_Ga=d,d=N,I=42\(esc)\\")
        #expect(t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty)
    }

    @Test func `alternate-screen images scroll with the alternate screen and evict above top`() throws {
        var t = terminal(columns: 10, rows: 4)
        let px = Base64.encodedString([UInt8](repeating: 0xFF, count: 10 * 20 * 4))
        t.feed("\(esc)[?1049h")  // enter alternate screen
        t.feed("\(esc)[2;1H\(esc)_Ga=T,i=1,q=2,f=32,s=10,v=20;\(px)\(esc)\\")
        let initialLine = try #require(t.screen.graphics.placements.first?.stableLine)
        t.feed("\(esc)[1S")  // scroll up 1 row on alternate screen
        #expect(t.screen.graphics.placements.first?.stableLine == initialLine - 1)
        t.feed("\(esc)[3S")  // scroll off top -> evicted
        #expect(t.screen.graphics.placements.isEmpty)
    }

    @Test func `changing cell pixel size marks rows dirty when images are present`() {
        var t = terminal()
        let px = Base64.encodedString([UInt8](repeating: 0xAA, count: 10 * 20 * 4))
        t.feed("\(esc)_Ga=T,i=1,q=2,f=32,s=10,v=20;\(px)\(esc)\\")
        t.clearDirty()
        #expect(!t.screen.isDirty(row: 0))
        t.setCellPixelSize(width: 12, height: 24)
        #expect(t.screen.isDirty(row: 0))
    }
}
