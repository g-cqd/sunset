import AemiTestKit
import Foundation
import Testing

@testable import SunsetCore

/// Comprehensive adversarial fuzzing of `Terminal` / `Screen` across every graphics, OSC, DCS, and VT400 protocol
/// (T-8 / t221):
/// - Sixel DCS decoder (`DCS P1;P2;P3 q ... ST`) — malformed rasters, extreme repeat counts, out-of-range colors
/// - iTerm2 inline images (`OSC 1337 ; File=...`) — bad base64, invalid PNG headers, extreme dimensions, quota bounds
/// - Kitty graphics & animation (`a=t`, `a=T`, `a=p`, `a=d`, `a=f`, `a=a`, `a=c`, `I=`, chunked `m=1`)
/// - VT400 rectangular ops (`DECFRA`, `DECERA`, `DECCRA`), `DECSET 45`, `XTSAVE`/`XTRESTORE`, `OSC 21`, and scrollback
///   search (`Screen.search`) & snapshotting (`Screen.snapshot`)
/// - Arbitrary chunk-boundary splits (verifying byte-at-a-time vs. whole-buffer streaming equivalence on `VTParser` +
///   `Screen`).
@Suite("Terminal graphics, OSC 21, and VT400 adversarial fuzzing")
struct TerminalProtocolFuzzTests {
    @Test func `Sixel decoder never traps or exceeds pixel bounds on 1000 adversarial payloads`() {
        var rng = SeededRNG(seed: 0x51_2026_1126)
        let alphabet: [UInt8] = Array(
            "0123456789;\"#!$-?@~ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz".utf8
        )
        for index in 0 ..< 1_000 {
            let len = rng.below(512)
            var bytes = [UInt8](repeating: 0, count: len)
            for i in 0 ..< len {
                bytes[i] =
                    rng.below(5) == 0 ? UInt8(truncatingIfNeeded: rng.next()) : alphabet[rng.below(alphabet.count)]
            }
            if let out = SixelDecoder.decode(bytes[...], transparentBackground: index.isMultiple(of: 2)) {
                #expect(out.width > 0 && out.width <= SixelDecoder.maxSide)
                #expect(out.height > 0 && out.height <= SixelDecoder.maxSide)
                #expect(out.width * out.height <= SixelDecoder.maxPixels)
                #expect(out.rgba.count == out.width * out.height * 4)
            }
        }
    }

    @Test func `iTerm2 OSC 1337 File= parser never traps or exceeds quota on 1000 adversarial inputs`() {
        var rng = SeededRNG(seed: 0x17_2026_1126)
        let prefixes = [
            "inline=1:",
            "inline=1;width=100px;height=50%;preserveAspectRatio=0:",
            "inline=1;width=999999999px;height=999999999%:",
            "inline=0;name=abc:",
            "width=auto;height=10:",
            ":",
            ""
        ]
        for _ in 0 ..< 1_000 {
            var bytes = Array(prefixes[rng.below(prefixes.count)].utf8)
            let len = rng.below(256)
            for _ in 0 ..< len {
                bytes.append(UInt8(truncatingIfNeeded: rng.next()))
            }
            if let req = ITermImageRequest.parse(bytes[...], maxBytes: 1 << 20) {
                #expect(req.data.count <= (1 << 20))
                #expect((1 ... TerminalGraphics.sideLimit).contains(req.pixelWidth))
                #expect((1 ... TerminalGraphics.sideLimit).contains(req.pixelHeight))
                let sized = req.resolvedSize(columns: 80, rows: 24, cellWidth: 8, cellHeight: 16)
                #expect(sized.cells.columns >= 1 && sized.cells.rows >= 1)
                #expect(sized.pixels.width >= 1 && sized.pixels.height >= 1)
            }
        }
    }

    @Test func `mixed Kitty animation, Sixel, OSC 21, VT400 rectangles, search and snapshot preserve all invariants`() {
        var rng = SeededRNG(seed: 0x74_2026_1126)
        let templates: [[UInt8]] = [
            Array("\u{1B}_Ga=T,i=1,f=32,s=2,v=2;AAAA".utf8),
            Array("\u{1B}_Ga=f,i=1,f=32,s=1,v=1,x=0,y=0,c=1,z=50;////".utf8),
            Array("\u{1B}_Ga=a,i=1,s=3,c=2,v=1".utf8),
            Array("\u{1B}_Ga=c,i=1,r=1,c=2,w=1,h=1,x=0,y=0,X=0,Y=0".utf8),
            Array("\u{1B}_Ga=d,d=N,I=1".utf8),
            Array("\u{1B}P0;1q\"1;1;10;12#1;2;100;0;0!10~-".utf8),
            Array("\u{1B}]1337;File=inline=1;width=10px:".utf8),
            Array("\u{1B}]21;foreground=?;background=#112233;color4=".utf8),
            Array("\u{1B}[35;1;1;10;10$x".utf8),
            Array("\u{1B}[1;1;5;5;1;2;2;1$v".utf8),
            Array("\u{1B}[1;1;24;80$z".utf8),
            Array("\u{1B}[?45h\u{1B}[?7;45;1049s".utf8),
            Array("\u{1B}[?7;45;1049r".utf8),
            Array("\u{1B}\\".utf8),
            [0x07, 0x08, 0x0A, 0x0D]
        ]
        var terminal = Terminal(columns: 40, rows: 12, scrollbackLimit: 200)
        terminal.setGraphicsQuota(bytes: 256 << 10)

        for step in 0 ..< 600 {
            var chunk: [UInt8] = []
            for _ in 0 ..< (1 + rng.below(6)) {
                chunk.append(contentsOf: templates[rng.below(templates.count)])
                let extra = rng.below(48)
                for _ in 0 ..< extra {
                    chunk.append(UInt8(truncatingIfNeeded: rng.next()))
                }
            }
            chunk.withUnsafeBufferPointer { terminal.feed($0.span) }
            let screen = terminal.screen
            #expect(screen.columns == 40 && screen.rows == 12)
            #expect(screen.row >= 0 && screen.row < screen.rows)
            #expect(screen.column >= 0 && screen.column < screen.columns)
            #expect(screen.graphics.bytes >= 0 && screen.graphics.bytes <= (256 << 10))
            #expect(screen.graphics.placements.count <= TerminalGraphics.placementLimit)
            #expect(screen.replies.count <= Screen.replyLimit)
            if step % 100 == 0 {
                _ = terminal.takeReplies()
                _ = screen.search(SearchQuery(text: "a", isRegex: false), limit: 50)
                _ = screen.snapshot(savedAt: 1_700_000_000, maximumLines: 100)
            }
        }
    }

    @Test func `streaming chunk splits produce identical screen state to whole-buffer feed`() {
        var rng = SeededRNG(seed: 0xCC_2026_1126)
        let payload = Array(
            ("Hello \u{1B}[31mworld\u{1B}[0m 日本語\r\n"
                + "\u{1B}[35;2;2;3;5$x"
                + "\u{1B}[?45h\u{1B}[?7;45s\u{1B}[?7l\u{1B}[?7;45r"
                + "\u{1B}]21;foreground=#123456;background=?\u{1B}\\"
                + "\u{1B}P0;1q\"1;1;8;6#1;2;100;50;0!8~\u{1B}\\"
                + "\u{1B}_Ga=T,i=7,f=32,s=1,v=1;/wAA/w==\u{1B}\\"
                + "\u{1B}_Ga=f,i=7,f=32,s=1,v=1,X=1;AP8A/w==\u{1B}\\"
                + "\u{1B}_Ga=a,i=7,c=2,s=3\u{1B}\\"
                + "done!")
                .utf8
        )

        var whole = Terminal(columns: 30, rows: 8)
        payload.withUnsafeBufferPointer { whole.feed($0.span) }

        var split = Terminal(columns: 30, rows: 8)
        var offset = 0
        while offset < payload.count {
            let take = min(1 + rng.below(7), payload.count - offset)
            payload[offset ..< offset + take].withUnsafeBufferPointer { split.feed($0.span) }
            offset += take
        }

        #expect(whole.screen.row == split.screen.row)
        #expect(whole.screen.column == split.screen.column)
        #expect(whole.screen.palette == split.screen.palette)
        #expect(whole.screen.graphics.images == split.screen.graphics.images)
        #expect(whole.screen.graphics.placements == split.screen.graphics.placements)
        #expect(whole.takeReplies() == split.takeReplies())
        for r in 0 ..< 8 {
            #expect(whole.screen.text(row: r) == split.screen.text(row: r))
        }
    }
}
