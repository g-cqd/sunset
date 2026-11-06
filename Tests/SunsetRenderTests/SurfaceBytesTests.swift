import SunsetCore
import Testing

@testable import SunsetRender

@Suite("Surface bytes") struct SurfaceBytesTests {
    @Test func `a pixel's bytes are red, green, blue, alpha, and a surface is read row by row`() {
        var surface = Surface(width: 2, height: 2)
        surface.pixels[0] = Surface.pack(RGB(1, 2, 3))
        surface.pixels[3] = Surface.pack(RGB(250, 251, 252))
        #expect(surface.rgbaBytes == [1, 2, 3, 255, 0, 0, 0, 255, 0, 0, 0, 255, 250, 251, 252, 255])
    }
}
