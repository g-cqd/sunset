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
}
