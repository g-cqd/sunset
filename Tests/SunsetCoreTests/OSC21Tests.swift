import AemiKernel
import Testing

@testable import SunsetCore

/// OSC 21, kitty's colour control protocol (T-1 / t183), as its spec has it (sw.kovidgoyal.net/kitty/color-stack, read
/// 2026-11-26): keys `foreground`, `background`, `cursor` and `0`...`255`; `key=?` queries, `key=value` sets, a bare `key`
/// resets, `key=` asks for a dynamic colour (ignored: Sunset has none); every key Sunset does not know is answered
/// `unknown=<base64 without padding>`, in order; answers use the request's terminator.
@Suite("OSC 21 kitty colour control") struct OSC21Tests {
    private func answer(_ t: inout Terminal, _ sequence: String) -> String {
        t.feed(sequence)
        return String(decoding: t.takeReplies(), as: UTF8.self)
    }

    @Test func `queries answer rgb:rr/gg/bb in request order, with the request's terminator`() {
        var t = Terminal(columns: 10, rows: 4)
        t.setDefaultColors(
            foreground: RGB(0x12, 0x34, 0x56),
            background: RGB(0xAB, 0xCD, 0xEF),
            cursor: RGB(0xFF, 0, 0x80)
        )
        #expect(
            answer(&t, "\(esc)]21;foreground=?;background=?;cursor=?\(esc)\\")
                == "\(esc)]21;foreground=rgb:12/34/56;background=rgb:ab/cd/ef;cursor=rgb:ff/00/80\(esc)\\"
        )
        let palette = t.screen.palette.colors
        let one = palette[1]
        let hex = { (value: UInt8) in
            String(value, radix: 16).count == 1 ? "0" + String(value, radix: 16) : String(value, radix: 16)
        }
        #expect(
            answer(&t, "\(esc)]21;1=?\u{07}")
                == "\(esc)]21;1=rgb:\(hex(one.red))/\(hex(one.green))/\(hex(one.blue))\u{07}"
        )
    }

    @Test func `palette keys are bare numbers, set and reset like the special colours`() {
        var t = Terminal(columns: 10, rows: 4)
        let (fg, bg, four) = (t.screen.palette.foreground, t.screen.palette.background, t.screen.palette.colors[4])
        #expect(
            answer(&t, "\(esc)]21;foreground=#112233;background=rgb:44/55/66;4=#ff8800;255=rgb:f/0/0\(esc)\\") == ""
        )
        #expect(t.screen.palette.foreground == RGB(0x11, 0x22, 0x33))
        #expect(t.screen.palette.background == RGB(0x44, 0x55, 0x66))
        #expect(t.screen.palette.colors[4] == RGB(0xFF, 0x88, 0x00))
        #expect(t.screen.palette.colors[255] == RGB(0xFF, 0, 0))
        // A bare key resets; `key=` (dynamic) changes nothing.
        #expect(answer(&t, "\(esc)]21;foreground=;background;4\(esc)\\") == "")
        #expect(t.screen.palette.foreground == RGB(0x11, 0x22, 0x33))
        #expect(t.screen.palette.background == bg && t.screen.palette.colors[4] == four)
        _ = fg
    }

    @Test func `set then query in one sequence answers the new value`() {
        var t = Terminal(columns: 10, rows: 4)
        #expect(answer(&t, "\(esc)]21;cursor=#0a0b0c;cursor=?\(esc)\\") == "\(esc)]21;cursor=rgb:0a/0b/0c\(esc)\\")
    }

    @Test func `unknown keys are answered unknown=base64 without padding, never echoed, in order`() {
        var t = Terminal(columns: 10, rows: 4)
        t.setDefaultColors(foreground: RGB(0xFF, 0, 0), background: nil, cursor: nil)
        #expect(
            answer(&t, "\(esc)]21;foreground=?;nonsense=?\(esc)\\")
                == "\(esc)]21;foreground=rgb:ff/00/00;unknown=bm9uc2Vuc2U\(esc)\\"
        )
        // Unknown even when set, and for out-of-range or non-decimal numbers; a key carrying an escape is not echoed.
        #expect(
            answer(&t, "\(esc)]21;256=#000;selection_background=red;color4=?;01x\(esc)\\")
                == "\(esc)]21;unknown=MjU2;unknown=c2VsZWN0aW9uX2JhY2tncm91bmQ;unknown=Y29sb3I0;unknown=MDF4\(esc)\\"
        )
    }

    @Test func `a value Sunset cannot read changes nothing and is not answered`() {
        var t = Terminal(columns: 10, rows: 4)
        let before = t.screen.palette
        #expect(answer(&t, "\(esc)]21;foreground=notacolor;background=rgb:zz/00/00;4=#12345\(esc)\\") == "")
        #expect(t.screen.palette == before)
    }

    @Test func `the # form keeps the most significant bits, as X11 and kitty say: #3a7 is #3000a0007000`() {
        #expect(Palette.parse(Array("#3a7".utf8)[...]) == RGB(0x30, 0xA0, 0x70))
        #expect(Palette.parse(Array("#33aa77".utf8)[...]) == RGB(0x33, 0xAA, 0x77))
        #expect(Palette.parse(Array("#3000a0007000".utf8)[...]) == RGB(0x30, 0xA0, 0x70))
        // The rgb: form scales: one digit f is ff.
        #expect(Palette.parse(Array("rgb:f/0/8".utf8)[...]) == RGB(0xFF, 0x00, 0x88))
    }
}
