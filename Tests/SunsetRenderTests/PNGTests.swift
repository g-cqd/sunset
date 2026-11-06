import SunsetCore
import Testing

@testable import SunsetRender

@Suite("PNG") struct PNGTests {
    @Test func `known checksums`() {
        #expect(PNG.crc32(Array("123456789".utf8)) == 0xCBF4_3926)
        #expect(PNG.adler32(Array("Wikipedia".utf8)) == 0x11E6_0398)
    }

    @Test func `a surface becomes a well-formed PNG`() {
        var surface = Surface(width: 3, height: 2)
        surface.pixels[0] = 0xFF00_00FF  // red
        let bytes = PNG.encode(surface)
        #expect(Array(bytes.prefix(8)) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        // IHDR: length 13, type, width 3, height 2, 8-bit RGBA.
        #expect(Array(bytes[8 ..< 16]) == [0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52])
        #expect(Array(bytes[16 ..< 24]) == [0, 0, 0, 3, 0, 0, 0, 2])
        #expect(Array(bytes[24 ..< 29]) == [8, 6, 0, 0, 0])
        #expect(Array(bytes.suffix(12)) == [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82])
        // The IDAT payload: zlib header, one stored block holding 2 rows of (1 + 12) bytes, whose first pixel is red.
        let idat = 33 + 8
        #expect(Array(bytes[idat ..< idat + 2]) == [0x78, 0x01])
        #expect(bytes[idat + 2] == 1)
        #expect(Array(bytes[idat + 3 ..< idat + 5]) == [26, 0])
        #expect(Array(bytes[idat + 7 ..< idat + 12]) == [0, 255, 0, 0, 255])
    }
}
