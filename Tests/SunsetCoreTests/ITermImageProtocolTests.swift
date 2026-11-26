import AemiKernel
import Testing

@testable import SunsetCore

/// iTerm2's inline images as iTerm2 itself does them (documentation-images.html, its `imgcat`, and
/// VT100InlineImageHelper.m, read 2026-11-26): the multipart form `MultipartFile=` / `FilePart=` / `FileEnd` (what
/// `imgcat` sends unless asked for `--legacy`), and the cursor left on the image's last row, just past it — past the
/// right edge when the image reaches it, so the next character wraps.
@Suite("iTerm2 inline images, as iTerm2 does them") struct ITermImageProtocolTests {
    /// A PNG's signature and header only: what Sunset reads of it here (its size).
    private static func png(width: Int, height: Int) -> [UInt8] {
        let be = { (value: Int) in [24, 16, 8, 0].map { UInt8((value >> $0) & 0xFF) } }
        return [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52]
            + be(width) + be(height) + [8, 6, 0, 0, 0, 0, 0, 0, 0]
    }

    private func terminal() -> Terminal {
        var t = Terminal(columns: 20, rows: 8)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    /// `imgcat`'s default: the arguments, then the base64 in 200-character parts (`fold -w 200`), then the end.
    private func multipart(_ args: String, _ data: [UInt8], part: Int = 200) -> String {
        let encoded = Array(Base64.encodedString(data))
        var out = "\(esc)]1337;MultipartFile=\(args)\u{07}"
        var index = 0
        while index < encoded.count {
            out += "\(esc)]1337;FilePart=\(String(encoded[index ..< min(index + part, encoded.count)]))\u{07}"
            index += part
        }
        return out + "\(esc)]1337;FileEnd\u{07}"
    }

    @Test func `a multipart file is placed as the single-sequence form places it`() throws {
        let image = Self.png(width: 40, height: 20) + [UInt8](repeating: 0x55, count: 600)
        var single = terminal()
        single.feed("\(esc)]1337;File=inline=1;width=20px:\(Base64.encodedString(image))\u{07}")
        var parts = terminal()
        parts.feed(multipart("inline=1;size=\(image.count);width=20px", image, part: 7 * 4))
        let placed = try #require(parts.screen.graphics.placements.first)
        #expect(parts.screen.graphics.placements.count == 1)
        #expect(placed.width == 20 && placed.height == 10 && placed.columns == 2 && placed.rows == 1)
        #expect(parts.screen.graphics.images[placed.image]?.pixels == image)
        #expect(single.screen.graphics.placements.map(\.columns) == [2])
        #expect(
            (parts.screen.cursorRow, parts.screen.cursorColumn) == (single.screen.cursorRow, single.screen.cursorColumn)
        )
    }

    @Test func `parts without a start, an end without parts, and a download are not images`() {
        var t = terminal()
        let image = Self.png(width: 4, height: 4)
        t.feed("\(esc)]1337;FilePart=\(Base64.encodedString(image))\u{07}\(esc)]1337;FileEnd\u{07}")
        t.feed(multipart("inline=0", image))
        t.feed("\(esc)]1337;MultipartFile=inline=1\u{07}\(esc)]1337;FileEnd\u{07}")
        #expect(t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty)
    }

    @Test func `parts past the image quota are dropped whole, and the next file still works`() {
        var t = terminal()
        t.setGraphicsQuota(bytes: 1 << 10)
        t.feed(multipart("inline=1", Self.png(width: 4, height: 4) + [UInt8](repeating: 1, count: 4_000)))
        #expect(t.screen.graphics.images.isEmpty)
        t.feed(multipart("inline=1", Self.png(width: 4, height: 4)))
        #expect(t.screen.graphics.images.count == 1)
    }

    @Test func `the cursor ends on the image's last row, just past it, and wraps when the image reaches the edge`() {
        var t = terminal()
        t.feed(
            "\(esc)[2;4H\(esc)]1337;File=inline=1;width=3;height=2:\(Base64.encodedString(Self.png(width: 30, height: 40)))\u{07}"
        )
        #expect(t.screen.cursorRow == 2 && t.screen.cursorColumn == 6, "row of the image's last line, column past it")

        var edge = terminal()
        let wide = Base64.encodedString(Self.png(width: 100, height: 20))
        edge.feed("\(esc)[1;11H\(esc)]1337;File=inline=1;width=10;height=1:\(wide)\u{07}X")
        #expect(
            edge.screen.text(row: 0).count <= 10,
            "X did not overwrite the image's last cell: \(edge.screen.text(row: 0))"
        )
        #expect(edge.screen.text(row: 1).hasPrefix("X"), "X wrapped to the next line")
    }
}
