import Foundation
import Testing

@testable import SunsetShell

/// Pasteboard image bounds (N-S8): header dimensions must pass `pixelLimit` without integer overflow before decoding.
@Suite("Pasteboard image pixel bounds")
struct PasteboardImageTests {
    @Test func `pixel limit accepts normal images and refuses zero, oversized, or overflowing dimensions`() {
        #expect(PasteboardImage.isWithinPixelLimit(width: 1920, height: 1080))
        #expect(PasteboardImage.isWithinPixelLimit(width: 4096, height: 4096))
        #expect(!PasteboardImage.isWithinPixelLimit(width: 0, height: 100))
        #expect(!PasteboardImage.isWithinPixelLimit(width: -1, height: 100))
        #expect(!PasteboardImage.isWithinPixelLimit(width: 10_000, height: 10_000))
        #expect(!PasteboardImage.isWithinPixelLimit(width: Int.max, height: 2))
    }

    @Test func `oversized PNG header is refused before decoding`() throws {
        // Minimal PNG header declaring 10000x10000 (100M px > 16M px limit).
        var png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        png.append(contentsOf: [0x00, 0x00, 0x00, 0x0D])
        png.append(contentsOf: "IHDR".utf8)
        png.append(contentsOf: [0x00, 0x00, 0x27, 0x10])  // 10000
        png.append(contentsOf: [0x00, 0x00, 0x27, 0x10])  // 10000
        png.append(contentsOf: [0x08, 0x02, 0x00, 0x00, 0x00])
        png.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        let dir = FileManager.default.temporaryDirectory.appending(path: "pasteboard-image-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appending(path: "bomb.png")
        try png.write(to: file)

        #expect(PasteboardImage.image(at: file) == nil)
    }
}
