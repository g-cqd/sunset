public import Foundation
import SunsetStorage

/// Pure, testable in-process core of `SunsetVaultService.xpc`: holds unlocked vault keys in `SecretBuffer`s keyed by
/// vault UUID and performs `WrappedKey.unwrap` + `Seal(.vaultRecord)` seal/open without ever exporting raw key bytes.
public final class VaultCryptoSession: @unchecked Sendable {
    private let lockObject = NSLock()
    private var keys: [UUID: SecretBuffer] = [:]

    public init() {}

    /// Unwraps `wrappedBlob` with `factorKey` and retains the resulting vault key inside `SecretBuffer`.
    public func unlock(wrappedBlob: Data, factorKey: Data, factor: String, vaultID: UUID) -> Bool {
        guard let wrapped = try? JSONDecoder().decode(WrappedKey.self, from: wrappedBlob),
            let key = try? wrapped.unwrap(with: factorKey, vault: vaultID)
        else { return false }
        let buffer = SecretBuffer(key.bytes)
        lockObject.lock()
        defer { lockObject.unlock() }
        keys[vaultID]?.wipe()
        keys[vaultID] = buffer
        return true
    }

    /// Retains a freshly created 32-byte key inside `SecretBuffer` for `vaultID`.
    public func install(rawKey: Data, vaultID: UUID) -> Bool {
        guard rawKey.count == 32 else { return false }
        let buffer = SecretBuffer(rawKey)
        lockObject.lock()
        defer { lockObject.unlock() }
        keys[vaultID]?.wipe()
        keys[vaultID] = buffer
        return true
    }

    /// Seals `plain` under `Seal(.vaultRecord)` for `identity` using the held key for `vaultID`.
    public func seal(plain: Data, identity: String, vaultID: UUID) -> Data? {
        withVaultSeal(vaultID: vaultID) { try? $0.seal(plain, identity: identity) }
    }

    /// Opens `sealed` under `Seal(.vaultRecord)` for `identity` using the held key for `vaultID`.
    public func open(sealed: Data, identity: String, vaultID: UUID) -> Data? {
        withVaultSeal(vaultID: vaultID) { try? $0.open(sealed, identity: identity) }
    }

    private func withVaultSeal(vaultID: UUID, _ body: (Seal) -> Data?) -> Data? {
        lockObject.lock()
        defer { lockObject.unlock() }
        guard let buffer = keys[vaultID] else { return nil }
        var output: Data?
        buffer.withBytes { bytes in
            output = body(Seal(key: StorageKey(bytes: Data(bytes)), purpose: .vaultRecord))
        }
        return output
    }

    /// Zeroes and drops the held key for `vaultID`.
    public func lock(vaultID: UUID) {
        lockObject.lock()
        defer { lockObject.unlock() }
        if let buffer = keys.removeValue(forKey: vaultID) {
            buffer.wipe()
        }
    }

    /// Whether a key is currently held for `vaultID`.
    public func isUnlocked(vaultID: UUID) -> Bool {
        lockObject.lock()
        defer { lockObject.unlock() }
        return keys[vaultID] != nil
    }
}
