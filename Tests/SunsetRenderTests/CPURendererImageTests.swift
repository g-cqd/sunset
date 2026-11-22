import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetRender

/// Images drawn by the CPU renderer (roadmap 0010 B, ADR-0117): over the cells they cover, above the text or below it, blended
/// when translucent, scaled to the cells asked, moving with the text, and the same when recorded and replayed.
@Suite("CPU renderer: images") struct CPURendererImageTests {
    private let red: [UInt8] = [255, 0, 0, 255]

    @Test func `an image is drawn over the cells it covers, and nothing else`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(KittyImages.show(id: 1, width: 16, height: 32, rgba: red), cursorVisible: false)
        #expect(rig.surface[0, 0] == RGB(255, 0, 0))
        #expect(rig.surface[15, 31] == RGB(255, 0, 0))
        #expect(rig.surface[16, 0] == black)
        #expect(rig.surface[0, 32] == black)
    }

    @Test func `above the text, unless the program puts it below (z < 0)`() {
        var above = CPURendererRig(10, 4)
        above.frame("█\r" + KittyImages.show(id: 1, width: 8, height: 16, rgba: red), cursorVisible: false)
        #expect(above.surface[4, 8] == RGB(255, 0, 0))
        var below = CPURendererRig(10, 4)
        below.frame(
            "█\r" + KittyImages.show(id: 1, width: 16, height: 16, rgba: red, options: "z=-1"),
            cursorVisible: false
        )
        #expect(below.surface[4, 8] == white)
        #expect(below.surface[12, 8] == RGB(255, 0, 0), "seen where there is no text")
    }

    @Test func `a translucent pixel is blended over what is below it`() {
        var rig = CPURendererRig(10, 4)
        rig.frame("█\r" + KittyImages.show(id: 1, width: 8, height: 16, rgba: [255, 0, 0, 128]), cursorVisible: false)
        // Red at alpha 128, premultiplied (128), over the text's white: (p × 255 + d × 127 + 127) / 255 a channel.
        func blended(_ image: Int, _ below: UInt8) -> UInt8 {
            UInt8((image * 255 + Int(below) * 127 + 127) / 255)
        }
        #expect(rig.surface[3, 3] == RGB(blended(128, white.red), blended(0, white.green), blended(0, white.blue)))
    }

    @Test func `scaled over the cells asked (c, r)`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(KittyImages.show(id: 1, width: 1, height: 1, rgba: red, options: "c=3,r=2"), cursorVisible: false)
        #expect(rig.surface[23, 31] == RGB(255, 0, 0))
        #expect(rig.surface[24, 0] == black)
        #expect(rig.surface[0, 32] == black)
    }

    @Test func `it moves with the text as the screen scrolls, and goes when deleted`() {
        var rig = CPURendererRig(10, 4)
        rig.frame("\n\n" + KittyImages.show(id: 1, width: 8, height: 16, rgba: red), cursorVisible: false)
        #expect(rig.surface[2, 2 * 16 + 2] == RGB(255, 0, 0))
        rig.frame("\n\n\n", cursorVisible: false)
        #expect(rig.surface[2, 2] == RGB(255, 0, 0), "scrolled up two lines with its text")
        #expect(rig.surface[2, 2 * 16 + 2] == black)
        rig.frame(KittyImages.deleteAll, cursorVisible: false)
        #expect(rig.surface[2, 2] == black)
    }

    @Test func `each row draws its own slice of an image over several`() {
        var rig = CPURendererRig(10, 4)
        // Red over its first 16 rows, blue over the next 16.
        let pixels: [UInt8] =
            Array(repeatElement([255, 0, 0, 255], count: 8 * 16).joined())
            + Array(repeatElement([0, 0, 255, 255], count: 8 * 16).joined())
        rig.frame(KittyImages.show(id: 1, width: 8, height: 32, pixels: pixels), cursorVisible: false)
        #expect(rig.surface[2, 2] == RGB(255, 0, 0))
        #expect(rig.surface[2, 18] == RGB(0, 0, 255))
        rig.frame("\n\n\n\n", cursorVisible: false)
        #expect(rig.surface[2, 2] == RGB(0, 0, 255), "its lower half on the top row after a scroll")
    }

    @Test func `an image sent again under its number takes its placements with it`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(KittyImages.show(id: 1, width: 8, height: 16, rgba: red), cursorVisible: false)
        rig.frame("\u{1B}_Ga=t,q=2,f=24,i=1,s=1,v=1;AAAA\u{1B}\\", cursorVisible: false)
        #expect(rig.surface[2, 2] == black)
    }

    @Test func `a PNG is drawn as its decoder reads it, and not at all without one`() throws {
        var green = Surface(width: 8, height: 16)
        for index in green.pixels.indices { green.pixels[index] = Surface.pack(RGB(0, 200, 0)) }
        let file = PNG.encode(green)
        var without = CPURendererRig(10, 4)
        without.frame(KittyImages.showPNG(id: 1, file), cursorVisible: false)
        #expect(without.surface[2, 2] == black)
        var with = CPURendererRig(10, 4, images: StubDecoder(image: green))
        with.frame(KittyImages.showPNG(id: 1, file), cursorVisible: false)
        #expect(with.surface[2, 2] == RGB(0, 200, 0))
    }

    @Test(arguments: [255, 200] as [UInt8])
    func `recorded and replayed, the pixels are the renderer's own`(alpha: UInt8) {
        let steps = [
            "ab█\r" + KittyImages.show(id: 1, width: 12, height: 20, rgba: [255, 0, 0, 160]),
            "\n\n" + KittyImages.show(id: 2, width: 3, height: 2, rgba: [0, 0, 255, 90], options: "c=4,r=2,z=-1"),
            "\n\n\nxyz", KittyImages.deleteAll + "end"
        ]
        var live = CPURendererRig(10, 5)
        var recorder = CPURendererRig(10, 5)
        (live.backgroundAlpha, recorder.backgroundAlpha) = (alpha, alpha)
        var replayed = Surface(width: live.surface.width, height: live.surface.height)
        for step in steps {
            live.frame(step, cursorVisible: false)
            recorder.terminal.feed(step)
            let frame = recorder.renderer.record(
                recorder.terminal.screen,
                width: replayed.width,
                height: replayed.height,
                cursorVisible: false,
                view: FrameView(backgroundAlpha: alpha)
            )
            recorder.terminal.clearDirty()
            frame.replay(onto: &replayed)
            #expect(replayed.pixels == live.surface.pixels, "after \(step.prefix(12).debugDescription)")
        }
    }
}
