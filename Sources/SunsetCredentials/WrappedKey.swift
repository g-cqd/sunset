import CryptoKit
public import Foundation
public import SunsetStorage

/// A vault's key wrapped by one unlock factor: sealed with the factor's key, bound to the vault. Changing the factor
/// rewraps this; the vault's records do not change.
public struct WrappedKey: Sendable, Equatable, Codable {
    public let factor: String
    public let sealed: Data

    /// `vaultKey` wrapped with `factorKey` for vault `vault`.
    public static func wrap(_ vaultKey: StorageKey, with factorKey: Data, factor: String, vault: UUID) throws
        -> WrappedKey
    {
        let box = try ChaChaPoly.seal(
            vaultKey.bytes,
            using: SymmetricKey(data: factorKey),
            authenticating: binding(factor, vault)
        )
        return WrappedKey(factor: factor, sealed: box.combined)
    }

    /// Why a vault's key did not unwrap: the factor's key is not this one's, or the wrap is another vault's or damaged (the
    /// three cannot be told apart, by design).
    public struct Refused: Error, Equatable {}

    /// The vault's key; throws `Refused` when `factorKey` is not this factor's or the wrap belongs to another vault.
    public func unwrap(with factorKey: Data, vault: UUID) throws(Refused) -> StorageKey {
        guard let box = try? ChaChaPoly.SealedBox(combined: sealed),
            let bytes = try? ChaChaPoly.open(
                box,
                using: SymmetricKey(data: factorKey),
                authenticating: Self.binding(factor, vault)
            )
        else { throw Refused() }
        return StorageKey(bytes: bytes)
    }

    /// What a wrap is bound to: its vault and its factor, so it cannot be moved between them.
    private static func binding(_ factor: String, _ vault: UUID) -> Data {
        Data("sunset-vault-key:\(vault.uuidString):\(factor)".utf8)
    }
}
