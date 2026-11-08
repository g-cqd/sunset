import Testing

@testable import SunsetHost

@Suite("LZFSE history codec") struct LZFSEHistoryCodecTests {
    private let codec = LZFSEHistoryCodec()

    /// Cells that look like text: a few scalar values and styles, mostly repeating.
    private func textLike(cells: Int) -> [UInt8] {
        var bytes: [UInt8] = []
        for index in 0 ..< cells {
            let word = UInt64(0x20 + (index * 7) % 60) | UInt64(index % 3) << 24
            withUnsafeBytes(of: word) { bytes.append(contentsOf: $0) }
        }
        return bytes
    }

    @Test func `text-like cells come back as they were, in much less space`() throws {
        let bytes = textLike(cells: 5000)
        let packed = try #require(bytes.withUnsafeBytes { codec.pack($0) })
        #expect(packed.count * 4 < bytes.count)
        var out = [UInt8](repeating: 0, count: bytes.count)
        #expect(out.withUnsafeMutableBytes { codec.unpack(packed, into: $0) })
        #expect(out == bytes)
    }

    @Test func `a packed result holds no more memory than its size`() throws {
        let packed = try #require(textLike(cells: 10_000).withUnsafeBytes { codec.pack($0) })
        // The input is 80 000 bytes: a result that kept the buffer it was made in would have a capacity of that size.
        #expect(packed.count < 8000 && packed.capacity <= packed.count + 64)
    }

    @Test func `bytes that do not get smaller are not packed`() {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        let noise = (0 ..< 4096)
            .map { _ -> UInt8 in
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return UInt8(truncatingIfNeeded: state >> 33)
            }
        #expect(noise.withUnsafeBytes { codec.pack($0) } == nil)
        #expect([UInt8]().withUnsafeBytes { codec.pack($0) } == nil)
    }

    @Test func `unpacking into a buffer of the wrong size, or from damaged bytes, fails instead of guessing`() throws {
        let bytes = textLike(cells: 1000)
        let packed = try #require(bytes.withUnsafeBytes { codec.pack($0) })
        var smaller = [UInt8](repeating: 0, count: bytes.count - 8)
        #expect(!smaller.withUnsafeMutableBytes { codec.unpack(packed, into: $0) })
        var larger = [UInt8](repeating: 0, count: bytes.count + 8)
        #expect(!larger.withUnsafeMutableBytes { codec.unpack(packed, into: $0) })
        var out = [UInt8](repeating: 0, count: bytes.count)
        #expect(!out.withUnsafeMutableBytes { codec.unpack(Array(packed.prefix(packed.count / 2)), into: $0) })
        #expect(!out.withUnsafeMutableBytes { codec.unpack([], into: $0) })
    }
}
