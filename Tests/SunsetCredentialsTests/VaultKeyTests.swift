import Foundation
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// The vault's key, wrapped once by each factor; a master password stretched with Argon2id.
@Suite("A vault's key and its factors")
struct VaultKeyTests {
    /// Cheap for tests; the real cost is measured, not tested here.
    private let cheap = MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1)

    @Test func `a password stretches to one key per salt; another password or salt, another key`() throws {
        let salt = Data(repeating: 1, count: 16)
        let key = try MasterPassword.stretch("correct horse", salt: salt, cost: cheap)
        #expect(key.count == 32)
        #expect(try MasterPassword.stretch("correct horse", salt: salt, cost: cheap) == key)
        #expect(try MasterPassword.stretch("correct horsf", salt: salt, cost: cheap) != key)
        #expect(try MasterPassword.stretch("correct horse", salt: Data(repeating: 2, count: 16), cost: cheap) != key)
    }

    @Test func `the vault key unwraps with its factor's key for its vault, not another's`() throws {
        let vaultKey = StorageKey.random()
        let vault = UUID()
        let factorKey = try MasterPassword.stretch("pw", salt: Data(repeating: 3, count: 16), cost: cheap)
        let wrapped = try WrappedKey.wrap(vaultKey, with: factorKey, factor: "password", vault: vault)
        #expect(wrapped.sealed.range(of: vaultKey.bytes) == nil, "the key is not in the wrap's bytes")
        #expect(try wrapped.unwrap(with: factorKey, vault: vault).bytes == vaultKey.bytes)
        let wrong = try MasterPassword.stretch("pX", salt: Data(repeating: 3, count: 16), cost: cheap)
        #expect(throws: WrappedKey.Refused.self) { try wrapped.unwrap(with: wrong, vault: vault) }
        #expect(throws: WrappedKey.Refused.self) { try wrapped.unwrap(with: factorKey, vault: UUID()) }
    }
}
