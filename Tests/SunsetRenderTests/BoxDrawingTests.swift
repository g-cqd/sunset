import SunsetCore
import Testing

@testable import SunsetRender

private func glyph(_ scalar: UInt32, _ width: Int = 8, _ height: Int = 16) -> (
    coverage: [UInt8], at: (Int, Int) -> UInt8
) {
    let bitmap = BuiltInGlyphs.bitmap(
        for: scalar,
        metrics: RenderMetrics(cellWidth: width, cellHeight: height),
        columns: 1
    )
    // A glyph that is not drawn gives no pixels, and the tests that read one fail on the values.
    let coverage = bitmap?.coverage ?? [UInt8](repeating: 0, count: width * height)
    return (coverage, { x, y in coverage[y * width + x] })
}

@Suite("Built-in glyphs") struct BoxDrawingTests {
    @Test func `a light line crosses the cell at its middle row and a light bar at its middle column`() {
        let horizontal = glyph(0x2500)
        for x in 0 ..< 8 { #expect(horizontal.at(x, 7) == 255) }
        #expect((0 ..< 16).filter { $0 != 7 }.allSatisfy { y in (0 ..< 8).allSatisfy { horizontal.at($0, y) == 0 } })
        let vertical = glyph(0x2502)
        for y in 0 ..< 16 { #expect(vertical.at(3, y) == 255) }
        #expect((0 ..< 8).filter { $0 != 3 }.allSatisfy { x in (0 ..< 16).allSatisfy { vertical.at(x, $0) == 0 } })
    }

    @Test func `a corner has two arms that meet in the middle`() {
        let corner = glyph(0x250C)
        #expect(corner.at(3, 7) == 255 && corner.at(7, 7) == 255 && corner.at(3, 15) == 255)
        #expect(corner.at(0, 7) == 0 && corner.at(3, 0) == 0)
    }

    @Test func `heavy lines are twice as thick`() {
        let heavy = glyph(0x2501)
        #expect((0 ..< 16).filter { heavy.at(4, $0) != 0 }.count == 2)
        #expect((0 ..< 16).filter { glyph(0x2500).at(4, $0) != 0 }.count == 1)
    }

    @Test func `a double line is two lines with a gap`() {
        let double = glyph(0x2550)
        #expect((0 ..< 16).filter { double.at(4, $0) != 0 } == [6, 8])
    }

    @Test func `a double corner joins its outer and inner lines`() {
        let corner = glyph(0x2554)  // right + down
        // Outer horizontal line (row 6) starts at the outer vertical (column 2), the inner (row 8) at the inner vertical (column 4).
        #expect(corner.at(2, 6) == 255 && corner.at(1, 6) == 0)
        #expect(corner.at(4, 8) == 255 && corner.at(3, 8) == 0)
        #expect(corner.at(2, 15) == 255 && corner.at(4, 15) == 255)
        #expect(corner.at(2, 5) == 0 && corner.at(4, 7) == 0)
        #expect(corner.at(7, 6) == 255 && corner.at(7, 8) == 255)
    }

    @Test func `blocks fill exactly what their names say`() {
        #expect(glyph(0x2588).coverage.allSatisfy { $0 == 255 })
        let upper = glyph(0x2580)
        #expect((0 ..< 16).allSatisfy { y in (0 ..< 8).allSatisfy { upper.at($0, y) == (y < 8 ? 255 : 0) } })
        let lowerEighth = glyph(0x2581)
        #expect((0 ..< 16).filter { lowerEighth.at(0, $0) != 0 } == [14, 15])
        let left = glyph(0x258C)
        #expect((0 ..< 8).allSatisfy { x in (0 ..< 16).allSatisfy { left.at(x, $0) == (x < 4 ? 255 : 0) } })
        #expect(glyph(0x2592).coverage.allSatisfy { $0 == 128 })
        let quadrant = glyph(0x2598)
        #expect(
            quadrant.at(0, 0) == 255 && quadrant.at(3, 7) == 255 && quadrant.at(4, 0) == 0 && quadrant.at(0, 8) == 0
        )
    }

    @Test func `braille draws one dot per bit`() {
        #expect(glyph(0x2800).coverage.allSatisfy { $0 == 0 })
        let all = glyph(0x28FF)
        #expect(all.coverage.filter { $0 != 0 }.count == 8 * 4)
        let first = glyph(0x2801)
        #expect(first.coverage.filter { $0 != 0 }.count == 4)
        #expect(first.at(1, 1) == 255)
    }

    @Test func `neighbouring glyphs join exactly where their arms say, for every glyph and several cell sizes`() {
        for (width, height) in [(8, 16), (10, 19), (9, 18), (7, 14), (12, 24)] {
            let metrics = RenderMetrics(cellWidth: width, cellHeight: height)
            let scalars = (0x2500 ... 0x257F as ClosedRange<UInt32>)
                .filter {
                    !(0x2504 ... 0x250B).contains($0) && !(0x254C ... 0x254F).contains($0)
                        && !(0x256D ... 0x2573).contains($0)
                }
            func bitmap(_ scalar: UInt32) -> [UInt8] {
                BuiltInGlyphs.bitmap(for: scalar, metrics: metrics, columns: 1)?.coverage ?? []
            }
            func column(_ scalar: UInt32, _ x: Int) -> [UInt8] { (0 ..< height).map { bitmap(scalar)[$0 * width + x] } }
            func row(_ scalar: UInt32, _ y: Int) -> [UInt8] { (0 ..< width).map { bitmap(scalar)[y * width + $0] } }
            func weight(_ scalar: UInt32, _ index: Int) -> Int { armWeights(scalar)[index] }
            for a in scalars {
                if weight(a, 1) == 0 {
                    #expect(
                        column(a, width - 1).allSatisfy { $0 == 0 },
                        "\(String(a, radix: 16)) right edge \(width)x\(height)"
                    )
                }
                if weight(a, 0) == 0 {
                    #expect(column(a, 0).allSatisfy { $0 == 0 }, "\(String(a, radix: 16)) left edge \(width)x\(height)")
                }
                if weight(a, 3) == 0 {
                    #expect(
                        row(a, height - 1).allSatisfy { $0 == 0 },
                        "\(String(a, radix: 16)) bottom edge \(width)x\(height)"
                    )
                }
                if weight(a, 2) == 0 {
                    #expect(row(a, 0).allSatisfy { $0 == 0 }, "\(String(a, radix: 16)) top edge \(width)x\(height)")
                }
                for b in scalars {
                    if weight(a, 1) != 0, weight(a, 1) == weight(b, 0) {
                        #expect(
                            column(a, width - 1) == column(b, 0),
                            "\(String(a, radix: 16)) → \(String(b, radix: 16)) \(width)x\(height)"
                        )
                    }
                    if weight(a, 3) != 0, weight(a, 3) == weight(b, 2) {
                        #expect(
                            row(a, height - 1) == row(b, 0),
                            "\(String(a, radix: 16)) ↓ \(String(b, radix: 16)) \(width)x\(height)"
                        )
                    }
                }
            }
        }
    }
}

/// The left, right, up, down weights of a box glyph, as the standard's charts give them (read from the renderer's table through its public behaviour is
/// circular, so the test keeps its own readings of the names: line, heavy and double strokes).
private func armWeights(_ scalar: UInt32) -> [Int] {
    BoxDrawing.testingArms(scalar)
}
