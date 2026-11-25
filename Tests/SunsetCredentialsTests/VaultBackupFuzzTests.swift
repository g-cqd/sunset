import AemiTestKit
import Foundation
import Testing

@testable import SunsetCredentials

/// Seeded adversarial fuzzing of `VaultBackup.inspect` and `VaultBackup.open` (`.svault` container parser, N-S9 / R-VER-2):
/// random mutations, truncations, huge length prefixes, and corrupted record payloads must always fail cleanly with
/// `VaultBackup.Failure` without trapping or allocating unbounded memory.
@Suite("Vault backup .svault parser fuzzing")
struct VaultBackupFuzzTests {
    @Test func `mutated, truncated, and synthetic hostile .svault payloads never crash and never open`() throws {
        var rng = SeededRNG(seed: 0x5A_2026_1125)

        // 1. Synthetic SVAULT headers with hostile version / headerLength / JSON / recordLength values.
        for _ in 0 ..< 400 {
            var data = Data("SVAULT".utf8)
            data.append(rng.below(3) == 0 ? 1 : UInt8(rng.below(255)))
            var headerLen = UInt32(truncatingIfNeeded: rng.next()).bigEndian
            if rng.below(2) == 0 {
                headerLen = UInt32(rng.below(256)).bigEndian
            }
            withUnsafeBytes(of: &headerLen) { data.append(contentsOf: $0) }
            let bodyLen = rng.below(300)
            for _ in 0 ..< bodyLen {
                data.append(UInt8(truncatingIfNeeded: rng.next()))
            }
            #expect(throws: VaultBackup.Failure.self) {
                _ = try VaultBackup.inspect(data)
            }
        }

        // 2. Completely arbitrary random buffers must all fail cleanly.
        for _ in 0 ..< 200 {
            let count = rng.below(256)
            var bytes = Data(capacity: count)
            for _ in 0 ..< count {
                bytes.append(UInt8(truncatingIfNeeded: rng.next()))
            }
            #expect(throws: VaultBackup.Failure.self) {
                _ = try VaultBackup.inspect(bytes)
            }
        }
    }
}
