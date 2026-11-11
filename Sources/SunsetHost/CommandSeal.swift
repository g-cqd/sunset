public import CryptoKit
import Foundation

/// The check that a kept terminal's command was written by Sunset, not by another program editing the session file (t145): an HMAC-SHA256 of the command,
/// keyed by a secret the app keeps in the Keychain. A program that can read that secret can forge it; one that can only write the session file cannot.
public struct CommandSeal: Sendable {
    private let key: SymmetricKey

    public init(key: SymmetricKey) { self.key = key }

    /// A new random key.
    public static func newKey() -> SymmetricKey { SymmetricKey(size: .bits256) }

    public func seal(_ command: String) -> String {
        Data(HMAC<SHA256>.authenticationCode(for: Data(command.utf8), using: key)).base64EncodedString()
    }

    /// Whether `seal` is this key's for exactly `command`; compared in constant time.
    public func verifies(_ command: String, seal: String?) -> Bool {
        guard let seal, let code = Data(base64Encoded: seal) else { return false }
        return HMAC<SHA256>.isValidAuthenticationCode(code, authenticating: Data(command.utf8), using: key)
    }
}
