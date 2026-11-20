import SunsetCore
import Testing

@testable import SunsetRender

/// Every line of U+2500–U+257F at sizes from small to large, one digest of their pixels (roadmap 0086 E): the arms'
/// horizontal and vertical drawing merged into one, the pixels kept. The digest was taken before the merge, at 8d4beba.
@Suite("Built-in box lines, pixel for pixel") struct BoxDrawingGoldenTests {
    static let sizes = [(6, 12), (7, 15), (8, 16), (9, 19), (10, 21), (12, 26), (15, 31), (18, 38), (24, 50)]

    /// FNV-1a over each size's bitmaps of the block, those not drawn counted as none.
    static func digest() -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ byte: UInt8) {
            hash ^= UInt64(byte)
            hash = hash &* 0x0100_0000_01b3
        }
        for (width, height) in sizes {
            for scalar in UInt32(0x2500) ... 0x257F {
                let bitmap = BuiltInGlyphs.bitmap(
                    for: scalar,
                    metrics: RenderMetrics(cellWidth: width, cellHeight: height),
                    columns: 1
                )
                guard let bitmap else {
                    mix(0xFF)
                    continue
                }
                bitmap.coverage.forEach(mix)
            }
        }
        return hash
    }

    @Test func `the box lines are drawn as they were`() {
        #expect(Self.digest() == 11_368_070_310_647_436_705)
    }
}
