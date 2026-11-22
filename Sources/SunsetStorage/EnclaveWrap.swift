import CryptoKit
public import Foundation
package import LocalAuthentication
package import Security

/// The storage key's wrap by this Mac's Secure Enclave (task t121, ADR-0104): a wrap key from two secrets, the P-256
/// ECDH of a Secure Enclave key with a key made for the wrap, and the ML-KEM-1024 decapsulation by another Secure Enclave
/// key, so that the wrap holds while either algorithm holds (a quantum attacker who harvested the record breaks only the
/// first). Both keys are made without Touch ID: the store opens at launch.
package enum EnclaveWrap {
    /// The wrap key: HKDF-SHA256 over both secrets, bound to what was exchanged (`transcript`).
    package static func wrapKey(classical: Data, postQuantum: Data, transcript: Data) -> Data {
        let key = HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: SymmetricKey(data: classical + postQuantum),
                salt: Data("sunset.storage-key.wrap.v1".utf8),
                info: transcript,
                outputByteCount: 32
            )
        return key.withUnsafeBytes { Data($0) }
    }

    /// A new wrap: two Secure Enclave keys made under `access`, and the wrap key they give, with the record that gives it
    /// back (its `sealed` empty, for the caller to fill or leave).
    package static func make(access: SecAccessControl) throws -> (wrapKey: Data, record: Record) {
        let classicalKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(accessControl: access)
        let postQuantumKey = try SecureEnclave.MLKEM1024.PrivateKey(accessControl: access)
        let ephemeral = P256.KeyAgreement.PrivateKey()
        let classical = try classicalKey.sharedSecretFromKeyAgreement(with: ephemeral.publicKey)
        let encapsulation = try postQuantumKey.publicKey.encapsulate()
        let record = Record(
            classicalKey: classicalKey.dataRepresentation,
            postQuantumKey: postQuantumKey.dataRepresentation,
            ephemeral: ephemeral.publicKey.x963Representation,
            encapsulated: encapsulation.encapsulated,
            sealed: Data()
        )
        let wrap = wrapKey(
            classical: classical.withUnsafeBytes { Data($0) },
            postQuantum: encapsulation.sharedSecret.withUnsafeBytes { Data($0) },
            transcript: record.transcript
        )
        return (wrap, record)
    }

    /// The wrap key `record` gives back; `context` is the one authentication both keys use, when theirs asks for one
    /// (Touch ID asked once, not once a key).
    package static func open(_ record: Record, context: LAContext? = nil) throws -> Data {
        let classicalKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(
            dataRepresentation: record.classicalKey,
            authenticationContext: context
        )
        let postQuantumKey = try SecureEnclave.MLKEM1024.PrivateKey(
            dataRepresentation: record.postQuantumKey,
            authenticationContext: context
        )
        let ephemeral = try P256.KeyAgreement.PublicKey(x963Representation: record.ephemeral)
        let classical = try classicalKey.sharedSecretFromKeyAgreement(with: ephemeral)
        let postQuantum = try postQuantumKey.decapsulate(record.encapsulated)
        return wrapKey(
            classical: classical.withUnsafeBytes { Data($0) },
            postQuantum: postQuantum.withUnsafeBytes { Data($0) },
            transcript: record.transcript
        )
    }

    /// What is kept: the two Secure Enclave keys (blobs only this Mac's Secure Enclave opens), the wrap's public key and
    /// ML-KEM ciphertext, and the key sealed (ChaCha20-Poly1305).
    package struct Record: Codable, Equatable {
        package var version = 1
        package var classicalKey: Data
        package var postQuantumKey: Data
        package var ephemeral: Data
        package var encapsulated: Data
        package var sealed: Data

        package init(classicalKey: Data, postQuantumKey: Data, ephemeral: Data, encapsulated: Data, sealed: Data) {
            self.classicalKey = classicalKey
            self.postQuantumKey = postQuantumKey
            self.ephemeral = ephemeral
            self.encapsulated = encapsulated
            self.sealed = sealed
        }

        package init(_ bytes: Data) throws {
            self = try PropertyListDecoder().decode(Self.self, from: bytes)
        }

        package var bytes: Data {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            return (try? encoder.encode(self)) ?? Data()
        }

        /// What the wrap key is bound to.
        var transcript: Data {
            ephemeral + encapsulated
        }
    }
}
