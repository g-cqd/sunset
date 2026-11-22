import CryptoKit
import Foundation
import Security
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// This Mac's Secure Enclave as a factor, its two keys (P-256 and ML-KEM-1024) usable only with Touch ID and only while
/// the fingers enrolled are those of when it was set. Here made without Touch ID, so that the tests ask no one; the
/// factor's own access is checked apart.
@Suite("A vault's Touch ID factor", .enabled(if: SecureEnclave.isAvailable))
struct TouchIDFactorTests {
    private func noPrompt() throws -> SecAccessControl {
        try #require(
            SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .privateKeyUsage, nil)
        )
    }

    @Test func `set, it gives the same key back, which wraps the vault key; the record holds none of it`() throws {
        let vault = UUID()
        let (factor, key) = try TouchIDFactor.make(vault: vault, access: noPrompt())
        #expect(try factor.factorKey(vault: vault) == key)
        let vaultKey = StorageKey.random()
        let wrapped = try WrappedKey.wrap(vaultKey, with: key, factor: "touch-id", vault: vault)
        #expect(try wrapped.unwrap(with: factor.factorKey(vault: vault), vault: vault).bytes == vaultKey.bytes)
        #expect(factor.bytes.range(of: key) == nil)
        #expect(try TouchIDFactor(factor.bytes) == factor, "kept and read back")
    }

    @Test func `another vault's, or a changed record, gives no key that opens it`() throws {
        let vault = UUID()
        let (factor, key) = try TouchIDFactor.make(vault: vault, access: noPrompt())
        #expect(try factor.factorKey(vault: UUID()) != key)
        // ML-KEM rejects implicitly: a changed ciphertext gives another secret, not an error; the vault key does not
        // unwrap with what it gives.
        let wrapped = try WrappedKey.wrap(StorageKey.random(), with: key, factor: "touch-id", vault: vault)
        var changed = factor
        changed.record.encapsulated[0] ^= 1
        let wrong = try changed.factorKey(vault: vault)
        #expect(wrong != key)
        #expect(throws: WrappedKey.Refused.self) { try wrapped.unwrap(with: wrong, vault: vault) }
    }

    @Test func `the factor's own keys need Touch ID, and the fingers enrolled when it was set`() {
        #expect(TouchIDFactor.flags.contains(.biometryCurrentSet) && TouchIDFactor.flags.contains(.privateKeyUsage))
    }
}
