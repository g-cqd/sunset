import Foundation
import Testing

@testable import SunsetStorage

@Suite("A key kept beside a named setup's files")
struct FileKeyVaultTests {
    @Test func `kept in a file only its owner reads; read back; a short file is no key`() throws {
        let folder = NSTemporaryDirectory() + "vault-\(UUID().uuidString)"
        let vault = FileKeyVault(path: folder + "/storage.key")
        #expect(try vault.read() == nil)
        let key = try StorageKeyring(vault: vault).key()
        #expect(try StorageKeyring(vault: vault).key().identifier == key.identifier)
        let mode = try FileManager.default.attributesOfItem(atPath: folder + "/storage.key")[.posixPermissions] as? Int
        #expect(mode == 0o600)
        try Data("short".utf8).write(to: URL(fileURLWithPath: folder + "/storage.key"))
        #expect(throws: StorageKeyFailure.vault) { try StorageKeyring(vault: vault).key() }
    }

    @Test func `the default places keep the key in the Keychain; a named setup beside its files`() {
        let own = StoragePlaces(environment: [:], home: "/h")
        #expect(own.isDefault && own.keyVault is KeychainKeyVault)
        let named = StoragePlaces(environment: ["SUNSET_CONFIG": "/t/c.json"], home: "/h")
        #expect(!named.isDefault && (named.keyVault as? FileKeyVault)?.path == "/t/storage.key")
    }
}
