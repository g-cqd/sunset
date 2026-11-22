import AemiArgon2
public import Foundation

/// The master password factor: Argon2id stretches the password with the factor's salt into a key that wraps the vault's
/// key. Its cost was measured on an M-series Mac (2026-11-21, release): 1 GiB, 3 passes, 4 lanes, about 0.64 s (p50),
/// 0.67 s (p90); 512 MiB and 4 passes about 0.40 s.
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

        /// Whether it is one Sunset would make: at most 2 GiB, 16 passes and 16 lanes, at least one of each. The cost is read
        /// from the vault's file, which whoever can write it can change (the outside audit's HIGH-02, 2026-11-22).
        public var isWithinBounds: Bool {
            (1 ... 2 << 20).contains(memoryKiB) && (1 ... 16).contains(passes) && (1 ... 16).contains(lanes)
        }
    }

    /// A cost past `Cost.isWithinBounds`, refused before any work.
    public struct CostRefused: Error {}

    /// The 32-byte key `password` stretches to with `salt` at `cost`.
    public static func stretch(_ password: String, salt: Data, cost: Cost) throws -> Data {
        guard cost.isWithinBounds else { throw CostRefused() }
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
