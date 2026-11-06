import Testing

@testable import SunsetRender

@Suite("Pixel kernels: blend") struct PixelKernelsTests {
    /// The formula in plain Swift, the definition both kernels are held to.
    private func expected(_ below: UInt32, coverage: UInt8, color: UInt32) -> UInt32 {
        if coverage == 0 { return below }
        let alpha = UInt32(coverage)
        var result: UInt32 = 0xFF00_0000
        for shift in [UInt32(0), 8, 16] {
            let channel = ((color >> shift) & 0xFF) * alpha + ((below >> shift) & 0xFF) * (255 - alpha) + 127
            result |= (channel / 255) << shift
        }
        return result
    }

    /// Runs a kernel over `pixels[offset...]` with `coverage` (the buffers are never empty pointers: an empty array gets a one-element stand-in).
    private func run(_ pixels: inout [UInt32], at offset: Int, coverage: [UInt8], color: UInt32, scalar: Bool) {
        let alphas = coverage.isEmpty ? [0] : coverage
        alphas.withUnsafeBufferPointer { source in
            pixels.withUnsafeMutableBufferPointer { buffer in
                guard let start = buffer.baseAddress, let covered = source.baseAddress else { return }
                if scalar {
                    unsafe PixelKernels.blendScalar(
                        start + offset,
                        coverage: covered,
                        count: coverage.count,
                        color: color
                    )
                } else {
                    unsafe PixelKernels.blend(start + offset, coverage: covered, count: coverage.count, color: color)
                }
            }
        }
    }

    private struct Random {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state >> 24
        }
    }

    @Test func `the scalar reference and the vector kernel equal the formula, for every length and alignment`() {
        var random = Random(state: 7)
        for length in 0 ... 70 {
            for offset in 0 ..< 4 {
                var below = (0 ..< length + offset)
                    .map { _ in 0xFF00_0000 | UInt32(truncatingIfNeeded: random.next()) & 0xFFFFFF }
                let coverage = (0 ..< length)
                    .map { _ -> UInt8 in
                        let draw = random.next() % 100
                        return draw < 40 ? 0 : draw < 55 ? 255 : UInt8(truncatingIfNeeded: random.next())
                    }
                let color = 0xFF00_0000 | UInt32(truncatingIfNeeded: random.next()) & 0xFFFFFF
                var scalar = below
                let want = (0 ..< length).map { expected(below[offset + $0], coverage: coverage[$0], color: color) }
                run(&below, at: offset, coverage: coverage, color: color, scalar: false)
                run(&scalar, at: offset, coverage: coverage, color: color, scalar: true)
                #expect(Array(below[offset...]) == want, "vector kernel, length \(length) offset \(offset)")
                #expect(Array(scalar[offset...]) == want, "scalar kernel, length \(length) offset \(offset)")
                #expect(Array(below[..<offset]) == Array(scalar[..<offset]), "nothing before the buffer is touched")
            }
        }
    }

    @Test func `every coverage value over every channel value of one color matches the formula`() {
        let color: UInt32 = 0xFF37_9AC8
        var below = (0 ..< 256)
            .map { UInt32(0xFF00_0000) | UInt32($0) << 16 | UInt32(255 - $0) << 8 | UInt32($0 ^ 0x5A) }
        for value in 0 ... 255 {
            let coverage = [UInt8](repeating: UInt8(value), count: 256)
            let want = below.map { expected($0, coverage: UInt8(value), color: color) }
            var result = below
            run(&result, at: 0, coverage: coverage, color: color, scalar: false)
            #expect(result == want, "coverage \(value)")
            below = want
        }
    }
}
