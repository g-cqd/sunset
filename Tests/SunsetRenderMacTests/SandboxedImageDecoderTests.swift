import Foundation
import Testing

@testable import SunsetRender
@testable import SunsetRenderMac

/// Sandboxed XPC image decoder (`SandboxedImageDecoder`, N-S5 / R-DES-2): validates out-of-process reply dimensions,
/// rejects truncated/overflowing RGBA buffers, and falls back to bounded `ImageIODecoder` only outside an app bundle.
@Suite("Sandboxed XPC image decoder")
struct SandboxedImageDecoderTests {
    @Test func `validates XPC reply dimensions and byte count without overflow`() {
        let valid = SandboxedImageDecoder.validatedReply(width: 2, height: 2, rgba: Data(repeating: 0xFF, count: 16))
        #expect(valid?.width == 2 && valid?.height == 2 && valid?.rgba.count == 16)

        #expect(SandboxedImageDecoder.validatedReply(width: 0, height: 2, rgba: Data()) == nil)
        #expect(SandboxedImageDecoder.validatedReply(width: 2, height: 2, rgba: Data(repeating: 0, count: 12)) == nil)
        #expect(SandboxedImageDecoder.validatedReply(width: 10_000, height: 10_000, rgba: Data()) == nil)
        #expect(SandboxedImageDecoder.validatedReply(width: Int.max, height: 2, rgba: Data()) == nil)
        #expect(SandboxedImageDecoder.validatedReply(width: 2, height: 2, rgba: nil) == nil)
    }

    @Test func `fallback decodes a valid PNG and refuses empty payloads when no XPC service is bundled`() throws {
        var surface = Surface(width: 2, height: 2)
        surface.pixels[0] = 0xFFFF_FFFF
        let png = PNG.encode(surface)

        let decoder = SandboxedImageDecoder(serviceName: nil)
        let decoded = try #require(decoder.decodePNG(png))
        #expect(decoded.width == 2 && decoded.height == 2)
        #expect(decoder.decodePNG([]) == nil)
    }
}
