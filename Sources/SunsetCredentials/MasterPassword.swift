import AemiArgon2
public import Foundation

/// The master password factor (ADR-0091): Argon2id stretches the password with the factor's salt into a key that wraps
/// the vault's key. Its cost was measured on the owner's Mac (M-series, 2026-11-21, release): 1 GiB, 3 passes, 4 lanes,
/// about 0.64 s (p50), 0.67 s (p90); 512 MiB and 4 passes about 0.40 s.
public enum MasterPassword {
    public struct Cost: Sendable, Equatable, Codable {
        public var memoryKiB: Int
        public var passes: Int
        public var lanes: Int

        public init(memoryKiB: Int, passes: Int, lanes: Int) {
            self.memoryKiB = memoryKiB
            self.passes = passes
            self.lanes = lanes
        }

        public static let standard = Cost(memoryKiB: 1 << 20, passes: 3, lanes: 4)
    }

    /// The 32-byte key `password` stretches to with `salt` at `cost`.
    public static func stretch(_ password: String, salt: Data, cost: Cost) throws -> Data {
        let parameters = try Argon2.Parameters(
            variant: .id,
            memoryKiB: cost.memoryKiB,
            passes: cost.passes,
            lanes: cost.lanes,
            tagLength: 32
        )
        var bytes = Array(password.utf8)
        defer { ConstantTime.wipe(&bytes) }
        let tag = try Argon2.hash(password: bytes, salt: Array(salt), parameters: parameters, threads: cost.lanes)
        return Data(tag)
    }
}
