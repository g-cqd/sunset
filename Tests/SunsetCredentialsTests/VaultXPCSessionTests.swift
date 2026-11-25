import Foundation
import SunsetStorage
import Testing

@testable import SunsetCredentials

/// App-Sandboxed Vault XPC crypto session (`VaultCryptoSession`, N-S5 / R-DES-2): verifies factor unwrapping,
/// identity-bound sealing/opening, cross-vault isolation, and key zeroing on lock without ever exporting raw keys.
@Suite("Vault XPC crypto session")
struct VaultXPCSessionTests {
    @Test func `unwraps factor, seals and opens records bound to identity, isolates vaults, and wipes on lock`() throws
    {
        let session = VaultCryptoSession()
        let vaultID = UUID()
        let otherVaultID = UUID()
        let vaultKey = StorageKey.random()
        let factorKey = StorageKey.random().bytes
        let wrapped = try WrappedKey.wrap(vaultKey, with: factorKey, factor: "password", vault: vaultID)
        let wrappedBlob = try JSONEncoder().encode(wrapped)

        #expect(!session.isUnlocked(vaultID: vaultID))
        #expect(
            !session.unlock(
                wrappedBlob: wrappedBlob,
                factorKey: Data(repeating: 0, count: 32),
                factor: "password",
                vaultID: vaultID
            )
        )
        #expect(session.unlock(wrappedBlob: wrappedBlob, factorKey: factorKey, factor: "password", vaultID: vaultID))
        #expect(session.isUnlocked(vaultID: vaultID))
        #expect(!session.isUnlocked(vaultID: otherVaultID))

        let plain = Data("top-secret-login".utf8)
        let identity = "vault:\(vaultID.uuidString)/record:\(UUID().uuidString)"
        let sealed = try #require(session.seal(plain: plain, identity: identity, vaultID: vaultID))
        #expect(sealed != plain)
        #expect(session.open(sealed: sealed, identity: identity, vaultID: vaultID) == plain)

        // Wrong identity or wrong vault must fail authentication.
        #expect(session.open(sealed: sealed, identity: "vault:other/record:wrong", vaultID: vaultID) == nil)
        #expect(session.open(sealed: sealed, identity: identity, vaultID: otherVaultID) == nil)

        // Locking zeroes and drops the key immediately.
        session.lock(vaultID: vaultID)
        #expect(!session.isUnlocked(vaultID: vaultID))
        #expect(session.open(sealed: sealed, identity: identity, vaultID: vaultID) == nil)
        #expect(session.seal(plain: plain, identity: identity, vaultID: vaultID) == nil)
    }
}
