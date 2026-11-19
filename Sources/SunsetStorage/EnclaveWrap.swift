import CryptoKit
public import Foundation

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
