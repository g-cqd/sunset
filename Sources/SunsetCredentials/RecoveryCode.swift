import CryptoKit
public import Foundation
import SunsetStorage

/// A vault's recovery code: 32 random bytes, shown once, in the storage key's form to write down (`RecoveryCodeText`:
/// Crockford's base 32 with a check, so that a slip is told as one). As much chance to guess as the vault key, so it is
/// not stretched: HKDF makes the key it wraps the vault's key with, bound to that vault.
public struct RecoveryCode: Equatable, Sendable {
    /// What was typed is not a recovery code: a character changed, missing or not of the code's alphabet.
    public struct Mistyped: Error, Equatable {}

    public let bytes: Data

    /// A new code.
    public static func generate() -> RecoveryCode {
        RecoveryCode(bytes: SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) })
    }

    /// The code as shown: groups of five characters joined by dashes.
    public var text: String {
        RecoveryCodeText.encode(bytes)
    }

    /// The code typed back: case, spaces and dashes do not matter, nor I, L or O for 1 and 0.
    public init(typed: String) throws(Mistyped) {
        guard let bytes = RecoveryCodeText.decode(typed) else { throw Mistyped() }
        self.bytes = bytes
    }

    init(bytes: Data) {
        self.bytes = bytes
    }

    /// The key this code wraps `vault`'s key with.
    public func factorKey(vault: UUID) -> Data {
        FactorKey.derive(bytes, kind: "recovery", vault: vault)
    }
}
