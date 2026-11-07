import Testing

@testable import SunsetRender

@Suite("Pixel kernels: blend over a translucent destination") struct PixelPremultipliedBlendTests {
    private struct Random {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state >> 24
        }
    }

    /// The formula: every channel, alpha included, is `(c * a + d * (255 - a) + 127) / 255` with the text colour opaque (alpha 255).
    private func expected(_ below: UInt32, coverage: UInt8, color: UInt32) -> UInt32 {
        if coverage == 0 { return below }
        let alpha = UInt32(coverage)
        var result: UInt32 = 0
        for shift in [UInt32(0), 8, 16] {
            let channel = ((color >> shift) & 0xFF) * alpha + ((below >> shift) & 0xFF) * (255 - alpha) + 127
            result |= (channel / 255) << shift
        }
        result |= ((255 * alpha + (below >> 24) * (255 - alpha) + 127) / 255) << 24
        return result
    }

    private func run(_ pixels: inout [UInt32], at offset: Int, coverage: [UInt8], color: UInt32, scalar: Bool) {
        let alphas = coverage.isEmpty ? [0] : coverage
        alphas.withUnsafeBufferPointer { source in
            pixels.withUnsafeMutableBufferPointer { buffer in
                guard let start = buffer.baseAddress, let covered = source.baseAddress else { return }
                if scalar {
                    unsafe PixelKernels.blendPremultipliedScalar(
                        start + offset,
                        coverage: covered,
                        count: coverage.count,
                        color: color
                    )
                } else {
                    unsafe PixelKernels.blendPremultiplied(
                        start + offset,
                        coverage: covered,
                        count: coverage.count,
                        color: color
                    )
                }
            }
        }
    }

    @Test func `both kernels equal the formula for every length and alignment, over every kind of destination alpha`() {
        var random = Random(state: 11)
        for length in 0 ... 70 {
            for offset in 0 ..< 4 {
                // A premultiplied destination: each colour channel at most the alpha.
                var below = (0 ..< length + offset)
                    .map { _ -> UInt32 in
                        let alpha = UInt32(random.next() % 4 == 0 ? 255 : random.next() % 256)
                        func channel() -> UInt32 { UInt32(random.next() % 256) * alpha / 255 }
                        return alpha << 24 | channel() << 16 | channel() << 8 | channel()
                    }
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
            }
        }
    }

    @Test func `over an opaque destination it gives the same pixels as the opaque kernel`() {
        var random = Random(state: 5)
        let count = 200
        let below = (0 ..< count).map { _ in 0xFF00_0000 | UInt32(truncatingIfNeeded: random.next()) & 0xFFFFFF }
        let coverage = (0 ..< count).map { _ in UInt8(truncatingIfNeeded: random.next()) }
        var general = below
        var fast = below
        let color: UInt32 = 0xFF37_9AC8
        coverage.withUnsafeBufferPointer { source in
            general.withUnsafeMutableBufferPointer { buffer in
                guard let start = buffer.baseAddress, let covered = source.baseAddress else { return }
                unsafe PixelKernels.blendPremultiplied(start, coverage: covered, count: count, color: color)
            }
            fast.withUnsafeMutableBufferPointer { buffer in
                guard let start = buffer.baseAddress, let covered = source.baseAddress else { return }
                unsafe PixelKernels.blend(start, coverage: covered, count: count, color: color)
            }
        }
        #expect(general == fast)
    }
}
