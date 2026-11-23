import Compression
import Foundation
import SunsetUpdate
import Testing

/// Streaming LZMA compression/decompression with a hard output cap (ADR-0125): never allocates past `maxOutput` on a
/// decompression bomb.
struct BoundedCompressionTests {
    @Test func roundTripsAndEnforcesOutputLimit() throws {
        let plain = Data(repeating: 0x41, count: 256_000)
        let compressed = try BoundedLZMA.compress(plain)
        #expect(compressed.count < 2_000, "highly compressible input")
        #expect(try BoundedLZMA.decompress(compressed, maxOutput: plain.count) == plain)
        #expect(throws: BoundedLZMA.Failure.outputLimitExceeded) {
            try BoundedLZMA.decompress(compressed, maxOutput: 4_096)
        }
        #expect(try BoundedLZMA.compress(Data()).isEmpty)
        #expect(try BoundedLZMA.decompress(Data(), maxOutput: 0).isEmpty)
    }

    @Test func refusesCorruptStreams() {
        #expect(throws: BoundedLZMA.Failure.malformed) {
            try BoundedLZMA.decompress(Data([0xFF, 0x00, 0x12, 0x34, 0x56]), maxOutput: 1024)
        }
    }
}
