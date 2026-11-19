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
            let classicalKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: record.classicalKey)
            let postQuantumKey = try SecureEnclave.MLKEM1024.PrivateKey(dataRepresentation: record.postQuantumKey)
            let ephemeral = try P256.KeyAgreement.PublicKey(x963Representation: record.ephemeral)
            let classical = try classicalKey.sharedSecretFromKeyAgreement(with: ephemeral)
            let postQuantum = try postQuantumKey.decapsulate(record.encapsulated)
            let wrap = EnclaveWrap.wrapKey(
                classical: classical.withUnsafeBytes { Data($0) },
                postQuantum: postQuantum.withUnsafeBytes { Data($0) },
                transcript: record.transcript
            )
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
        let record: EnclaveWrap.Record
        do {
            let classicalKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(accessControl: access)
            let postQuantumKey = try SecureEnclave.MLKEM1024.PrivateKey(accessControl: access)
            let ephemeral = P256.KeyAgreement.PrivateKey()
            let classical = try classicalKey.sharedSecretFromKeyAgreement(with: ephemeral.publicKey)
            let encapsulation = try postQuantumKey.publicKey.encapsulate()
            let transcript = ephemeral.publicKey.x963Representation + encapsulation.encapsulated
            let wrap = EnclaveWrap.wrapKey(
                classical: classical.withUnsafeBytes { Data($0) },
                postQuantum: encapsulation.sharedSecret.withUnsafeBytes { Data($0) },
                transcript: transcript
            )
            let sealed = try ChaChaPoly.seal(bytes, using: SymmetricKey(data: wrap)).combined
            record = EnclaveWrap.Record(
                classicalKey: classicalKey.dataRepresentation,
                postQuantumKey: postQuantumKey.dataRepresentation,
                ephemeral: ephemeral.publicKey.x963Representation,
                encapsulated: encapsulation.encapsulated,
                sealed: sealed
            )
        } catch {
            throw .vault
        }
        try backing.write(record.bytes)
    }

    public func remove() throws(StorageKeyFailure) {
        try backing.remove()
    }
}
