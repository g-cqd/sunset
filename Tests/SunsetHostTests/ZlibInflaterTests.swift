import Compression
import Testing

@testable import SunsetHost

/// Compressed images as programs send them, zlib streams (roadmap 0010 D): inflated whole and checked, never past their
/// limit, refused when cut short, altered or not zlib.
@Suite("Zlib inflater") struct ZlibInflaterTests {
    /// `bytes` as a zlib stream: the header, deflate data from Compression, the Adler-32 checksum.
    private func zlib(_ bytes: [UInt8]) -> [UInt8] {
        var deflated = [UInt8](repeating: 0, count: bytes.count + 1_024)
        let count = deflated.withUnsafeMutableBufferPointer { target in
            bytes.withUnsafeBufferPointer { source -> Int in
                guard let to = target.baseAddress, let from = source.baseAddress else { return 0 }
                return compression_encode_buffer(to, target.count, from, source.count, nil, COMPRESSION_ZLIB)
            }
        }
        let sum = ZlibInflater.adler32(bytes)
        return [0x78, 0x9C] + deflated.prefix(count) + [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: sum >> $0) }
    }

    private let picture: [UInt8] = (0 ..< 30_000).map { UInt8(truncatingIfNeeded: $0 * 7 / 3) }

    @Test func `a whole stream is inflated to what was compressed`() {
        #expect(ZlibInflater().inflate(zlib(picture), limit: picture.count) == picture)
        #expect(ZlibInflater().inflate(zlib(picture), limit: 1 << 20) == picture)
    }

    @Test func `past its limit, cut short, altered, or not zlib: refused`() {
        let stream = zlib(picture)
        #expect(ZlibInflater().inflate(stream, limit: picture.count - 1) == nil, "past the limit")
        #expect(
            ZlibInflater().inflate(Array(stream.prefix(stream.count / 2)) + stream.suffix(4), limit: 1 << 20) == nil,
            "cut"
        )
        var altered = stream
        altered[altered.count - 1] ^= 1
        #expect(ZlibInflater().inflate(altered, limit: 1 << 20) == nil, "checksum")
        var dictionary = stream
        dictionary[1] = 0xBB  // FDICT set (0x78BB is a multiple of 31)
        #expect(ZlibInflater().inflate(dictionary, limit: 1 << 20) == nil, "preset dictionary")
        #expect(ZlibInflater().inflate(Array("not zlib at all".utf8), limit: 1 << 20) == nil)
    }

    @Test func `a small stream that would inflate huge writes no more than its limit`() {
        let zeros = [UInt8](repeating: 0, count: 8 << 20)
        let bomb = zlib(zeros)
        #expect(bomb.count < 64 << 10, "\(bomb.count) bytes stand for 8 MiB")
        #expect(ZlibInflater().inflate(bomb, limit: 1 << 20) == nil)
    }

    @Test func `Adler-32 as zlib computes it`() {
        #expect(ZlibInflater.adler32(Array("Wikipedia".utf8)) == 0x11E6_0398)
        #expect(ZlibInflater.adler32([]) == 1)
    }
}
