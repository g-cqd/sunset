import Foundation
import SunsetUpdate
import Testing

/// Our own binary delta (roadmap 0122 C, ADR-0122): what `BinaryDelta.make` writes, `BinaryDelta.apply` turns back into
/// the new file; a malformed delta is refused, never read out of bounds.
struct BinaryDeltaTests {
    /// Bytes from a seeded generator: deterministic, not compressible.
    static func bytes(_ count: Int, seed: UInt64) -> [UInt8] {
        var state = seed
        return (0 ..< count)
            .map { _ in
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return UInt8(truncatingIfNeeded: state >> 56)
            }
    }

    /// `old` edited as builds edit an executable: bytes changed here and there, a block inserted, one removed.
    static func edited(_ old: [UInt8]) -> [UInt8] {
        var new = old
        for index in stride(from: 100, to: new.count, by: 997) { new[index] &+= 3 }
        new.insert(contentsOf: bytes(5000, seed: 9), at: new.count / 3)
        let removed = min(4000, new.count / 4)
        new.removeSubrange((new.count / 2) ..< (new.count / 2 + removed))
        return new
    }

    @Test(arguments: [0, 1, 17, 70_000])
    func makesWhatItIsAppliedToBackIntoTheNewFile(size: Int) throws {
        let old = Self.bytes(size, seed: 1)
        for new in [Self.edited(old), old, [], Self.bytes(3000, seed: 2)] {
            let delta = try BinaryDelta.make(from: Data(old), to: Data(new))
            #expect(try BinaryDelta.apply(delta, to: Data(old)) == Data(new))
        }
    }

    @Test func isMuchSmallerThanTheNewFileForAnEditedOne() throws {
        let old = Self.bytes(200_000, seed: 3)
        let new = Self.edited(old)
        let delta = try BinaryDelta.make(from: Data(old), to: Data(new))
        #expect(delta.count < new.count / 10)
    }

    @Test func refusesWhatIsNotADelta() {
        #expect(throws: BinaryDelta.Failure.notADelta) {
            try BinaryDelta.apply(Data("hello, not a delta at all".utf8), to: Data())
        }
    }

    @Test func refusesADeltaForAnotherOldFile() throws {
        let old = Data(Self.bytes(5000, seed: 4))
        let delta = try BinaryDelta.make(from: old, to: Data(Self.edited(Array(old))))
        #expect(throws: BinaryDelta.Failure.otherOldFile) { try BinaryDelta.apply(delta, to: old.dropLast(1)) }
    }

    @Test func refusesEveryTruncationAndNeverReadsOutOfBounds() throws {
        let old = Data(Self.bytes(3000, seed: 5))
        let delta = try BinaryDelta.make(from: old, to: Data(Self.edited(Array(old))))
        for length in stride(from: 0, to: delta.count, by: 7) {
            #expect(throws: BinaryDelta.Failure.self) { try BinaryDelta.apply(delta.prefix(length), to: old) }
        }
    }
}
