import Testing

@testable import SunsetRender
@testable import SunsetRenderMac

/// The PNG files programs send, read with ImageIO (ADR-0117): premultiplied, at their size; anything else refused.
@Suite("ImageIO decoder") struct ImageIODecoderTests {
    @Test func `a PNG is read premultiplied, at its size`() throws {
        var surface = Surface(width: 3, height: 2)
        // Straight RGBA in the file: red 200, green 100, blue 50 at alpha 128; then opaque white.
        surface.pixels[0] = 200 | 100 << 8 | 50 << 16 | 128 << 24
        surface.pixels[1] = 0xFFFF_FFFF
        let decoded = try #require(ImageIODecoder().decodePNG(PNG.encode(surface)))
        #expect(decoded.width == 3 && decoded.height == 2)
        let first = Array(decoded.rgba[0 ..< 4]).map(Int.init)
        // 200 × 128 / 255 ≈ 100.4, 100 × 128 / 255 ≈ 50.2, 50 × 128 / 255 ≈ 25.1: within one of rounding.
        for (value, expected) in zip(first, [100, 50, 25, 128]) { #expect(abs(value - expected) <= 1, "\(first)") }
        #expect(Array(decoded.rgba[4 ..< 8]) == [255, 255, 255, 255])
    }

    @Test func `what is not a PNG is not read`() {
        #expect(ImageIODecoder().decodePNG([]) == nil)
        #expect(ImageIODecoder().decodePNG(Array("GIF89a not a png at all".utf8)) == nil)
        var truncated = PNG.encode(Surface(width: 4, height: 4))
        truncated.removeLast(truncated.count / 2)
        #expect(ImageIODecoder().decodePNG(truncated) == nil)
    }

    @Test func `a PNG larger than the renderer draws is refused from its header`() {
        // A header saying 4,097 × 4,097 pixels (16.8 M, over the 16 M a picture may have): refused. (That the size is read
        // before ImageIO makes the image is not seen from here: the forged header breaks the file too.)
        var big = PNG.encode(Surface(width: 1, height: 1))
        let side: [UInt8] = [0, 0, 0x10, 0x01]
        big.replaceSubrange(16 ..< 24, with: side + side)
        #expect(ImageIODecoder().decodePNG(big) == nil)
    }
}
