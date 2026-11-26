import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetRender
@testable import SunsetRenderMetal

/// Images drawn by Metal against the CPU renderer, the oracle (roadmap 0010 B): above and below the text, translucent, scaled,
/// over several rows, scrolled, deleted; on an opaque and on a translucent window.
@Suite("Metal renderer against the CPU oracle: images", .serialized) struct MetalImageDifferentialTests {
    @Test(arguments: [255, 200] as [UInt8])
    func `images agree pixel for pixel, frame after frame`(alpha: UInt8) async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        rig.alpha = alpha
        // Half red, half translucent blue: rows that differ, a slice each.
        let red: [UInt8] = Array(repeatElement([255, 0, 0, 255] as [UInt8], count: 20 * 30).joined())
        let blue: [UInt8] = Array(repeatElement([0, 60, 255, 120] as [UInt8], count: 20 * 30).joined())
        let pixels = red + blue
        let steps = [
            "ab█\r" + KittyImages.show(id: 1, width: 20, height: 60, pixels: pixels),
            "\n\n\(KittyImages.show(id: 2, width: 3, height: 2, rgba: [0, 200, 90, 140], options: "c=5,r=2,z=-1"))text",
            KittyImages.show(id: 3, width: 9, height: 7, rgba: [250, 250, 0, 255]) + "\n\n\nmore",
            "\n\n\n\n",
            KittyImages.deleteAll + "end"
        ]
        for step in steps {
            try await rig.frame(step)
            let difference = rig.differences()
            #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
        }
    }

    @Test func `the comparison sees images: a frame drawn without them differs`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        try await rig.frame(KittyImages.show(id: 1, width: 20, height: 20, rgba: [255, 0, 0, 255]))
        #expect(rig.differences().count == 0)
        let red = rig.cpuSurface[5, 5]
        #expect(red == RGB(255, 0, 0), "the CPU drew it")
        #expect(rig.gpuSurface()[5, 5] == red, "Metal drew it")
    }

    @Test(arguments: [255, 200] as [UInt8])
    func `layers, parts and offsets agree pixel for pixel`(alpha: UInt8) async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        rig.alpha = alpha
        let steps = [
            "\u{1B}[41mab\u{1B}[0m█\r"
                + KittyImages.show(id: 1, width: 30, height: 40, rgba: [0, 200, 0, 150], options: "z=-5,X=3,Y=5"),
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
        for step in steps {
            try await rig.frame(step)
            let difference = rig.differences()
            #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
        }
    }

    @Test func `Sixel and Kitty animation frames agree pixel for pixel between CPU and Metal`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        let (px, py) = (rig.metrics.paddingX, rig.metrics.paddingY)
        // Sixel 16x12 (red top 6px, green bottom 6px)
        let sixel = "\u{1B}P0;1q\"1;1;16;12#1;2;100;0;0#1!16~-#2;2;0;100;0#2!16~\u{1B}\\"
        try await rig.frame(sixel)
        let diff1 = rig.differences()
        #expect(diff1.count == 0, "\(diff1.count) pixels differ on Sixel frame")
        #expect(rig.cpuSurface[px + 2, py + 2] == RGB(255, 0, 0))
        #expect(rig.gpuSurface()[px + 2, py + 2] == RGB(255, 0, 0))
        #expect(rig.cpuSurface[px + 2, py + 8] == RGB(0, 255, 0))
        #expect(rig.gpuSurface()[px + 2, py + 8] == RGB(0, 255, 0))

        // Kitty animated image at row 0 col 0: frame 1 blue, frame 2 yellow, switch to frame 2 (`a=a,c=2`)
        let root = "\u{1B}[H" + KittyImages.show(id: 50, width: 8, height: 8, rgba: [0, 0, 255, 255])
        let frame2 =
            KittyImages.frame(id: 50, width: 8, height: 8, rgba: [255, 255, 0, 255], options: "X=1")
            + "\u{1B}_Ga=a,i=50,c=2,s=3,q=2\u{1B}\\"
        try await rig.frame(root)
        #expect(rig.differences().count == 0)
        #expect(rig.cpuSurface[px + 2, py + 2] == RGB(0, 0, 255))
        try await rig.frame(frame2)
        let diff2 = rig.differences()
        #expect(diff2.count == 0, "\(diff2.count) pixels differ on Kitty animation frame 2")
        #expect(rig.cpuSurface[px + 2, py + 2] == RGB(255, 255, 0))
        #expect(rig.gpuSurface()[px + 2, py + 2] == RGB(255, 255, 0))
    }
}
