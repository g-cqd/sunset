import CryptoKit
import Foundation

/// The key a factor wraps a vault's key with, from the factor's secret: HKDF-SHA256, salted by the factor's kind, bound to
/// the vault (ADR-0091). For secrets with a key's strength (a recovery code, the Secure Enclave's wrap), not passwords.
public enum FactorKey {
    static func derive(_ secret: Data, kind: String, vault: UUID) -> Data {
        HKDF<SHA256>
            .deriveKey(
                inputKeyMaterial: SymmetricKey(data: secret),
                salt: Data("sunset-vault-\(kind)".utf8),
                info: Data(vault.uuidString.utf8),
                outputByteCount: 32
            )
            .withUnsafeBytes { Data($0) }
    }
}
