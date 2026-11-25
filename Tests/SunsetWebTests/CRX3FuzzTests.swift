import AemiTestKit
import Foundation
import Testing

@testable import SunsetWebModel

/// Seeded adversarial fuzzing of `CRX3Signature` / `ExtensionPackage.zip(from:)` (N-S9 / R-VER-2): random protobuf
/// headers, truncated varints, huge length prefixes, flipped signature bytes, and raw non-ZIP payloads must always be
/// refused cleanly without trapping or allocating unbounded memory.
@Suite("CRX3 parser fuzzing")
struct CRX3FuzzTests {
    @Test func `random and mutated CRX3 payloads never crash and never bypass signature verification`() throws {
        let signer = SignedCRX.ecdsa()
        let valid = try SignedCRX.package([signer], idKey: signer.spki)
        var rng = SeededRNG(seed: 0xC3_2026_1125)

        // 1. Single-byte and slice mutations of a valid signed CRX3 must all be refused.
        for _ in 0 ..< 250 {
            var mutated = valid
            let index = rng.below(mutated.count)
            mutated[index] ^= UInt8(1 + rng.below(255))
            #expect(throws: ExtensionPackage.Refused.self) {
                try ExtensionPackage.zip(from: mutated)
            }
        }

        // 2. Truncated prefixes of a valid CRX3 must all be refused.
        for cut in stride(from: 0, to: valid.count, by: max(1, valid.count / 40)) {
            #expect(throws: ExtensionPackage.Refused.self) {
                try ExtensionPackage.zip(from: valid.prefix(cut))
            }
        }

        // 3. Synthetic Cr24 headers with hostile header sizes and random protobuf bodies.
        for _ in 0 ..< 250 {
            var data = Data("Cr24".utf8)
            var version = UInt32(rng.below(5)).littleEndian
            withUnsafeBytes(of: &version) { data.append(contentsOf: $0) }
            var headerSize = UInt32(truncatingIfNeeded: rng.next()).littleEndian
            if rng.below(2) == 0 {
                headerSize = UInt32(rng.below(128)).littleEndian
            }
            withUnsafeBytes(of: &headerSize) { data.append(contentsOf: $0) }
            let bodyLen = rng.below(160)
            for _ in 0 ..< bodyLen {
                data.append(UInt8(truncatingIfNeeded: rng.next()))
            }
            #expect(throws: ExtensionPackage.Refused.self) {
                try ExtensionPackage.zip(from: data)
            }
        }
    }
}
