public import Foundation

/// The key in a file beside a named setup's files (a test, a second setup named by `$SUNSET_CONFIG`): such a setup never
/// touches the person's Keychain. A key beside what it seals protects nothing; the person's own setup uses the Keychain.
public struct FileKeyVault: KeyVault {
    public let path: String

    public init(path: String) {
        self.path = path
    }

    public func read() throws(StorageKeyFailure) -> Data? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let bytes = FileManager.default.contents(atPath: path) else { throw .vault }
        return bytes
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        do {
            try StoredFile.write(bytes, to: path, durability: .forced)
        } catch {
            throw .vault
        }
    }

    public func remove() throws(StorageKeyFailure) {
        guard FileManager.default.fileExists(atPath: path) else { return }
        do { try FileManager.default.removeItem(atPath: path) } catch { throw .vault }
    }
}
