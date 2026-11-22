import Foundation
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// ADR-0091: "any one opens the vault, or two if the person asks for two". Two factors make one key that needs both.
@Suite("Two factors at once")
struct FactorPairTests {
    private let password = (kind: "password", key: Data(repeating: 1, count: 32))
    private let touchID = (kind: "touch-id", key: Data(repeating: 2, count: 32))

    @Test func `the pair's key needs both: either alone does not open what it wraps`() throws {
        let vault = UUID()
        let pair = FactorKey.pair(password, touchID, vault: vault)
        #expect(pair.kind == "password+touch-id")
        let vaultKey = StorageKey.random()
        let wrapped = try WrappedKey.wrap(vaultKey, with: pair.key, factor: pair.kind, vault: vault)
        #expect(try wrapped.unwrap(with: pair.key, vault: vault).bytes == vaultKey.bytes)
        #expect(throws: WrappedKey.Refused.self) { try wrapped.unwrap(with: password.key, vault: vault) }
        #expect(throws: WrappedKey.Refused.self) { try wrapped.unwrap(with: touchID.key, vault: vault) }
    }

    @Test func `the same whichever is given first; another vault, another key`() {
        let vault = UUID()
        #expect(FactorKey.pair(password, touchID, vault: vault) == FactorKey.pair(touchID, password, vault: vault))
        #expect(
            FactorKey.pair(password, touchID, vault: vault).key != FactorKey.pair(password, touchID, vault: UUID()).key
        )
    }
}
