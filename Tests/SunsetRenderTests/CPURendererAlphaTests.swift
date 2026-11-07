import SunsetCore
import Testing

@testable import SunsetRender

/// A translucent default background: the window has a material, glass or nothing behind it. Pixels are premultiplied (colour times alpha), as a layer's
/// contents must be.
@Suite("CPU renderer: translucent background") struct CPURendererAlphaTests {
    private func premultiplied(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: UInt8) -> UInt32 {
        func scale(_ value: UInt8) -> UInt32 { (UInt32(value) * UInt32(alpha) + 127) / 255 }
        return UInt32(alpha) << 24 | scale(blue) << 16 | scale(green) << 8 | scale(red)
    }

    private func rig(alpha: UInt8) -> CPURendererRig {
        var rig = CPURendererRig()
        rig.backgroundAlpha = alpha
        // The default background is #c86432.
        rig.terminal.feed("\u{1B}]11;#c86432\u{7}")
        return rig
    }

    @Test func `the default background is the colour times the alpha, with that alpha`() {
        var rig = rig(alpha: 128)
        rig.frame(cursorVisible: false)
        let want = premultiplied(200, 100, 50, alpha: 128)
        #expect(
            rig.surface.pixels.allSatisfy { $0 == want },
            "got \(String(rig.surface.pixels[0], radix: 16)), want \(String(want, radix: 16))"
        )
    }

    @Test func `fully opaque is what it always was, and fully transparent is nothing at all`() {
        var opaque = rig(alpha: 255)
        opaque.frame(cursorVisible: false)
        #expect(opaque.surface.pixels.allSatisfy { $0 == Surface.pack(RGB(200, 100, 50)) })
        var clear = rig(alpha: 0)
        clear.frame(cursorVisible: false)
        #expect(clear.surface.pixels.allSatisfy { $0 == 0 })
    }

    @Test func `a cell with a background colour of its own stays opaque`() {
        var rig = rig(alpha: 100)
        rig.frame("\u{1B}[44m  ", cursorVisible: false)
        #expect(rig.pixel(row: 0, column: 0, x: 3, y: 3) == RGB(0, 0, 238), "the blue of SGR 44")
        #expect(rig.surface.pixels[3 * rig.surface.width + 3] >> 24 == 255)
        #expect(
            rig.surface.pixels[3 * rig.surface.width + 3 * 8 + 3] >> 24 == 100,
            "the next cell is the default background"
        )
    }

    @Test func `text over the translucent background is opaque where its coverage is full`() {
        var rig = rig(alpha: 100)
        rig.frame("a", cursorVisible: false)
        // The box glyph is solid inside its cell (2 pixels in), except the marker pixel at its top left.
        #expect(rig.pixel(row: 0, column: 0, x: 5, y: 6) == white)
        #expect(rig.surface.pixels[6 * rig.surface.width + 5] >> 24 == 255)
        #expect(
            rig.surface.pixels[0] == premultiplied(200, 100, 50, alpha: 100),
            "outside the glyph: still the background"
        )
    }

    @Test func `partial coverage over the translucent background mixes colour and alpha exactly`() {
        var rig = rig(alpha: 100)
        rig.frame("a", cursorVisible: false)
        // The marker pixel of the box glyph has coverage 1 + 97 % 250 = 98 for "a" (U+0061 = 97).
        let coverage: UInt32 = 98
        let below = premultiplied(200, 100, 50, alpha: 100)
        func mix(_ colour: UInt32, _ under: UInt32) -> UInt32 {
            (colour * coverage + under * (255 - coverage) + 127) / 255
        }
        // The text colour is the default foreground, 229 in each channel; its alpha is 255.
        let text: UInt32 = 229
        let red = mix(text, below & 255)
        let green = mix(text, (below >> 8) & 255)
        let blue = mix(text, (below >> 16) & 255)
        let alpha = (255 * coverage + 100 * (255 - coverage) + 127) / 255
        let expected = alpha << 24 | blue << 16 | green << 8 | red
        #expect(
            rig.surface.pixels[2 * rig.surface.width + 2] == expected,
            "got \(String(rig.surface.pixels[2 * rig.surface.width + 2], radix: 16))"
        )
    }

    @Test func `changing the alpha draws the whole frame again, with nothing dirty`() {
        var rig = rig(alpha: 255)
        rig.frame("hello", cursorVisible: false)
        rig.backgroundAlpha = 90
        rig.frame(cursorVisible: false)
        #expect(rig.surface.pixels[0] == premultiplied(200, 100, 50, alpha: 90))
        #expect(rig.surface.pixels[rig.surface.pixels.count - 1] == premultiplied(200, 100, 50, alpha: 90))
    }
}
