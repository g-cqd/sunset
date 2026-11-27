import CryptoKit
public import Foundation
import Security

/// The storage key wrapped by this Mac's Secure Enclave (`EnclaveWrap`), the record kept by `backing` (the data-protection
/// keychain in the app). Read or written where the Secure Enclave or the backing cannot be used: `.vault`.
public struct EnclaveKeyVault: KeyVault {
    let backing: any KeyVault

    public init(backing: any KeyVault) {
        self.backing = backing
    }

    public func read() throws(StorageKeyFailure) -> Data? {
        guard let stored = try backing.read() else { return nil }
        let opened: (key: Data, bound: Bool)
        do {
            let record = try EnclaveWrap.Record(stored)
            var wrap = try EnclaveWrap.open(record)
            defer { wrap.resetBytes(in: 0 ..< wrap.count) }
            let box = try ChaChaPoly.SealedBox(combined: record.sealed)
            let key = SymmetricKey(data: wrap)
            if let bound = try? ChaChaPoly.open(box, using: key, authenticating: Self.binding(record)) {
                opened = (bound, true)
            } else {
                // Sealed before the record was bound (audit HIGH-03): opened, then sealed again bound.
                opened = (try ChaChaPoly.open(box, using: key), false)
            }
        } catch {
            throw .vault
        }
        if !opened.bound { try? write(opened.key) }
        return opened.key
    }

    /// What the sealed key is bound to: its purpose and its record's own public parts, so that a sealed key moved into
    /// another record does not open (audit HIGH-03).
    static func binding(_ record: EnclaveWrap.Record) -> Data {
        Data("sunset.storage-key.v1".utf8) + record.ephemeral + record.encapsulated
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        guard SecureEnclave.isAvailable,
            // After the first unlock, not only while unlocked: a Mac app runs in an unlocked session, and what it seals
            // while the screen is locked (a download ending, the session kept at sleep) must still be sealed. This
            // device only: never in a backup or on another Mac (audit HIGH-03, decided 2026-11-27).
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                .privateKeyUsage,
                nil
            )
        else { throw .vault }
        var record: EnclaveWrap.Record
        do {
            var made = try EnclaveWrap.make(access: access)
            defer { made.wrapKey.resetBytes(in: 0 ..< made.wrapKey.count) }
            record = made.record
            record.sealed =
                try ChaChaPoly.seal(
                    bytes,
                    using: SymmetricKey(data: made.wrapKey),
                    authenticating: Self.binding(record)
                )
                .combined
        } catch {
            throw .vault
        }
        try backing.write(record.bytes)
    }

    public func remove() throws(StorageKeyFailure) {
        try backing.remove()
    }
}
