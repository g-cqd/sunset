import CryptoKit
public import Foundation

/// The key that seals what Sunset keeps: 32 random bytes, made on first use and kept in a `KeyVault`. Nothing is sealed with
/// it directly: each purpose has a key derived from it (`Seal`), so what is sealed for one purpose cannot be opened as
/// another.
public struct StorageKey: Sendable {
    private let key: SymmetricKey

    /// A key from its 32 bytes: a vault's key unwrapped (Sunset's own modules only).
    package init(bytes: Data) {
        key = SymmetricKey(data: bytes)
    }

    package static func random() -> StorageKey {
        StorageKey(bytes: SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) })
    }

    /// The key a recovery code holds.
    public init(recoveryCode: String) throws(StorageKeyFailure) {
        guard let bytes = RecoveryCodeText.decode(recoveryCode) else { throw .badCode }
        self.init(bytes: bytes)
    }

    /// Its 32 bytes: to wrap a vault's key with a factor (Sunset's own modules only).
    package var bytes: Data {
        key.withUnsafeBytes { Data($0) }
    }

    /// The key in a form to write down. Whoever has it and the files reads everything: shown once, on request.
    public var recoveryCode: String {
        RecoveryCodeText.encode(bytes)
    }

    /// Four bytes that name the key without giving anything of it away: written in every seal, so that a thing sealed with
    /// another key is told apart from a damaged one.
    public var identifier: Data {
        derived("key-id", count: 4).withUnsafeBytes { Data($0) }
    }

    func derived(_ purpose: String, count: Int = 32) -> SymmetricKey {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: key,
                info: Data("sunset.storage.v1/\(purpose)".utf8),
                outputByteCount: count
            )
    }
}
