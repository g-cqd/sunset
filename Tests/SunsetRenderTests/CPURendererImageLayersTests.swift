import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetRender

/// Images drawn as kitty draws them (roadmap 0010 C): three layers (over the text; under the text but over coloured cell
/// backgrounds, `z` < 0; under those backgrounds too, `z` < −1,073,741,824), a part of an image (`x`, `y`, `w`, `h`), from a
/// point within its first cell (`X`, `Y`).
@Suite("CPU renderer: image layers, parts and offsets") struct CPURendererImageLayersTests {
    private let red = RGB(255, 0, 0)

    /// Row 0: a blue-backed blank cell, then a full block in the default colours; an opaque red image over both, at `z`.
    private func layered(_ z: Int) -> CPURendererRig {
        var rig = CPURendererRig(10, 4)
        rig.frame(
            "\(esc)[44m \(esc)[0m█\r"
                + KittyImages.show(id: 1, width: 16, height: 16, rgba: [255, 0, 0, 255], options: "z=\(z)"),
            cursorVisible: false
        )
        return rig
    }

    @Test func `three layers: over the text; under it over coloured backgrounds; under those too`() {
        var plain = CPURendererRig(10, 4)
        plain.frame("\(esc)[44m \(esc)[0m█", cursorVisible: false)
        let blue = plain.surface[4, 8]
        let over = layered(0)
        #expect(over.surface[4, 8] == red && over.surface[12, 8] == red)
        let middle = layered(-1)
        #expect(middle.surface[4, 8] == red, "over the blue background")
        #expect(middle.surface[12, 8] == white, "under the text")
        let under = layered(-1_073_741_825)
        #expect(under.surface[4, 8] == blue, "under the blue background")
        #expect(under.surface[12, 8] == white)
    }

    @Test func `a part of the image: x, y, w, h`() {
        // 16 × 16: red on the left half, blue on the right.
        let pixels: [UInt8] = (0 ..< 16 * 16).flatMap { $0 % 16 < 8 ? [255, 0, 0, 255] : [0, 0, 255, 255] as [UInt8] }
        var rig = CPURendererRig(10, 4)
        rig.frame(
            KittyImages.show(id: 1, width: 16, height: 16, pixels: pixels, options: "x=8,w=8"),
            cursorVisible: false
        )
        #expect(rig.surface[2, 2] == RGB(0, 0, 255))
        #expect(rig.surface[9, 2] == black, "8 pixels wide only")
    }

    @Test func `from a point within the first cell: X, Y`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(
            KittyImages.show(id: 1, width: 4, height: 4, rgba: [255, 0, 0, 255], options: "X=4,Y=14"),
            cursorVisible: false
        )
        #expect(rig.surface[2, 2] == black)
        #expect(rig.surface[5, 15] == red)
        #expect(rig.surface[5, 17] == red, "into the next row, which it covers")
        #expect(rig.surface[5, 19] == black)
    }

    @Test(arguments: [255, 200] as [UInt8])
    func `recorded and replayed, with layers, parts and offsets`(alpha: UInt8) {
        let steps = [
            "\(esc)[41mab\(esc)[0m█\r"
                + KittyImages.show(id: 1, width: 20, height: 30, rgba: [0, 200, 0, 150], options: "z=-5,X=3,Y=5"),
            "\n\n"
                + KittyImages.show(
                    id: 2,
                    width: 12,
                    height: 12,
                    rgba: [0, 0, 255, 255],
                    options: "x=2,y=3,w=7,h=6,c=3,z=-1073741900"
                ),
            "\n\n\nxyz"
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
