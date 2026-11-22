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
        do {
            let record = try EnclaveWrap.Record(stored)
            let wrap = try EnclaveWrap.open(record)
            return try ChaChaPoly.open(ChaChaPoly.SealedBox(combined: record.sealed), using: SymmetricKey(data: wrap))
        } catch {
            throw .vault
        }
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        guard SecureEnclave.isAvailable,
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                .privateKeyUsage,
                nil
            )
        else { throw .vault }
        var record: EnclaveWrap.Record
        do {
            let made = try EnclaveWrap.make(access: access)
            record = made.record
            record.sealed = try ChaChaPoly.seal(bytes, using: SymmetricKey(data: made.wrapKey)).combined
        } catch {
            throw .vault
        }
        try backing.write(record.bytes)
    }

    public func remove() throws(StorageKeyFailure) {
        try backing.remove()
    }
}
