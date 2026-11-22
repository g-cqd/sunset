import CryptoKit
import Foundation
import Testing

@testable import SunsetStorage

/// The storage key sealed by a wrap key from two Secure Enclave keys of this Mac, a P-256 one and an ML-KEM-1024 one:
/// the wrap holds while either holds. The Secure Enclave works ad hoc signed (-14).
@Suite("The storage key, wrapped by the Secure Enclave", .enabled(if: SecureEnclave.isAvailable))
struct EnclaveKeyVaultTests {
    private let key = Data((0 ..< 32).map { UInt8($0) })

    @Test func `the wrap key needs both secrets: either one changed, it changes`() {
        let classical = Data(repeating: 1, count: 32)
        let quantum = Data(repeating: 2, count: 32)
        let transcript = Data("ciphertexts".utf8)
        let both = EnclaveWrap.wrapKey(classical: classical, postQuantum: quantum, transcript: transcript)
        #expect(
            both
                != EnclaveWrap.wrapKey(
                    classical: classical,
                    postQuantum: Data(repeating: 3, count: 32),
                    transcript: transcript
                )
        )
        #expect(
            both
                != EnclaveWrap.wrapKey(
                    classical: Data(repeating: 3, count: 32),
                    postQuantum: quantum,
                    transcript: transcript
                )
        )
        #expect(both != EnclaveWrap.wrapKey(classical: classical, postQuantum: quantum, transcript: Data("other".utf8)))
        #expect(both == EnclaveWrap.wrapKey(classical: classical, postQuantum: quantum, transcript: transcript))
    }

    @Test func `written then read: the same key; the record holds no byte of it, and only this Mac opens it`() throws {
        let backing = MemoryKeyVault()
        let vault = EnclaveKeyVault(backing: backing)
        try vault.write(key)
        let record = try #require(backing.stored)
        #expect(record.range(of: key) == nil)
        #expect(try vault.read() == key)
        // A record whose ML-KEM ciphertext was changed does not open: the wrap needs both halves.
        var changed = try EnclaveWrap.Record(record)
        changed.encapsulated[0] ^= 1
        let tampered = MemoryKeyVault()
        try tampered.write(changed.bytes)
        #expect(throws: StorageKeyFailure.vault) { try EnclaveKeyVault(backing: tampered).read() }
    }

    @Test func `nothing kept: nil; the backing refuses (no data-protection keychain): it says so`() throws {
        #expect(try EnclaveKeyVault(backing: MemoryKeyVault()).read() == nil)
        #expect(throws: StorageKeyFailure.vault) {
            try EnclaveKeyVault(backing: MemoryKeyVault(failing: true)).write(key)
        }
    }
}
