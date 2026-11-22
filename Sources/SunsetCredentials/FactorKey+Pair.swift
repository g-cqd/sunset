public import Foundation

/// Two factors at once (ADR-0091: "any one opens the vault, or two if the person asks for two").
extension FactorKey {
    /// The key two factors make together: HKDF over both keys, in the order of their kinds so that either order gives the
    /// same, bound to `vault`; its kind names both ("password+touch-id"). Either key alone is not it.
    public static func pair(
        _ first: (kind: String, key: Data),
        _ second: (kind: String, key: Data),
        vault: UUID
    ) -> Pair {
        let both = [first, second].sorted { $0.kind < $1.kind }
        let kind = both.map(\.kind).joined(separator: "+")
        return Pair(kind: kind, key: derive(both[0].key + both[1].key, kind: kind, vault: vault))
    }

    /// Two factors' key, and the kind it is kept under.
    public struct Pair: Equatable, Sendable {
        public let kind: String
        public let key: Data
    }
}
