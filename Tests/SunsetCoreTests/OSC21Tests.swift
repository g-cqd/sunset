import Testing

@testable import SunsetCore

/// Tests OSC 21 (kitty colour control protocol — T-1 / t183): querying, setting, and resetting foreground, background,
/// cursor, and indexed palette colours (`color0`..`color255`) in single and batched sequences.
@Suite("OSC 21 kitty colour control") struct OSC21Tests {
    @Test func `queries return rgb:RRRR/GGGG/BBBB using the request terminator`() {
        var t = Terminal(columns: 10, rows: 4)
        t.setDefaultColors(
            foreground: RGB(0x12, 0x34, 0x56),
            background: RGB(0xAB, 0xCD, 0xEF),
            cursor: RGB(0xFF, 0x00, 0x80)
        )
        t.feed("\(esc)]21;foreground=?;background=?;cursor=?\(esc)\\")
        let replyST = String(decoding: t.takeReplies(), as: UTF8.self)
        #expect(
            replyST
                == "\(esc)]21;foreground=rgb:1212/3434/5656;background=rgb:abab/cdcd/efef;cursor=rgb:ffff/0000/8080\(esc)\\"
        )

        t.feed("\(esc)]21;color1=?\u{07}")
        let replyBEL = String(decoding: t.takeReplies(), as: UTF8.self)
        #expect(replyBEL.hasPrefix("\(esc)]21;color1=rgb:") && replyBEL.hasSuffix("\u{07}"))
    }

    @Test func `sets and resets dynamic and indexed colours in one sequence`() {
        var t = Terminal(columns: 10, rows: 4)
        let originalBG = t.screen.palette.background
        let originalColor4 = t.screen.palette.colors[4]

        t.feed("\(esc)]21;foreground=#112233;background=rgb:44/55/66;cursor=#abcdef;color4=#ff8800\(esc)\\")
        #expect(t.screen.palette.foreground == RGB(0x11, 0x22, 0x33))
        #expect(t.screen.palette.background == RGB(0x44, 0x55, 0x66))
        #expect(t.screen.palette.cursor == RGB(0xAB, 0xCD, 0xEF))
        #expect(t.screen.palette.colors[4] == RGB(0xFF, 0x88, 0x00))

        // Empty value resets back to seed defaults.
        t.feed("\(esc)]21;background=;color4=\(esc)\\")
        #expect(t.screen.palette.background == originalBG)
        #expect(t.screen.palette.colors[4] == originalColor4)
        #expect(t.screen.palette.foreground == RGB(0x11, 0x22, 0x33))
    }

    @Test func `unknown keys, out-of-range color indices, and invalid specs are ignored without trapping`() {
        var t = Terminal(columns: 10, rows: 4)
        let before = t.screen.palette
        t.feed("\(esc)]21;unknown=#112233;color256=#112233;color-1=#112233;foreground=notacolor;noequals\(esc)\\")
        #expect(t.screen.palette == before)
        #expect(t.takeReplies().isEmpty)
    }
}
