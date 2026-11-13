public import Foundation

/// Where the key is kept: the login Keychain in the app (`KeychainKeyVault`), memory in tests.
public protocol KeyVault: Sendable {
    /// The key's bytes; nil when none was ever kept.
    func read() throws(StorageKeyFailure) -> Data?
    /// Keeps these bytes as the key, in place of any other.
    func write(_ bytes: Data) throws(StorageKeyFailure)
}
