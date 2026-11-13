import Foundation
import Testing

@testable import SunsetStorage

/// Touches the login Keychain, under a name of its own that it removes: run only when asked (`SUNSET_KEYCHAIN_TEST=1`).
@Suite(
    "The key in the login Keychain",
    .enabled(if: ProcessInfo.processInfo.environment["SUNSET_KEYCHAIN_TEST"] == "1")
)
struct KeychainKeyVaultTests {
    @Test func `nothing at first; a key is kept, read back, replaced and removed`() throws {
        let vault = KeychainKeyVault(service: "studio.aemi.sunset.storage-key.test-\(UUID().uuidString)")
        defer { try? vault.remove() }
        #expect(try vault.read() == nil)
        let ring = StorageKeyring(vault: vault)
        let key = try ring.key()
        #expect(try vault.read()?.count == 32)
        #expect(try ring.key().identifier == key.identifier)
        let other = StorageKey(bytes: Data(repeating: 7, count: 32))
        #expect(try ring.restore(code: other.recoveryCode, replacing: true).identifier == other.identifier)
        #expect(try vault.read() == Data(repeating: 7, count: 32))
        try vault.remove()
        #expect(try vault.read() == nil)
    }
}
