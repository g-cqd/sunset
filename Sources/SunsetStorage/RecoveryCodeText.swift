import CryptoKit
package import Foundation

/// The key in a form to write down: its 32 bytes and two bytes that check them, in Crockford's base 32 (no I, L, O or U, so
/// nothing is mistaken for a digit), as eleven groups of five. Read back whatever the case, with spaces or dashes, and with O,
/// I and L taken for the digits they look like; a mistyped code fails the check.
package enum RecoveryCodeText {
    private static let text = FiveBitText("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let keyLength = 32
    private static let checkLength = 2
    /// Symbols in a code: 34 bytes, five bits a symbol.
    static let symbols = ((keyLength + checkLength) * 8 + 4) / 5

    package static func encode(_ key: Data) -> String {
        let symbols = text.symbols(Array(key) + check(key))
        return stride(from: 0, to: symbols.count, by: 5)
            .map { String(symbols[$0 ..< min($0 + 5, symbols.count)]) }
            .joined(separator: "-")
    }

    /// The key a code holds; nil when it is not a code, or its check fails.
    package static func decode(_ code: String) -> Data? {
        let typed = code.uppercased().filter { $0 != "-" && !$0.isWhitespace }
            .map { (character: Character) -> Character in
                switch character {
                    case "O": "0"
                    case "I", "L": "1"
                    default: character
                }
            }
        // The bits left over after the last byte are padding: zero in a code we made.
        guard let read = text.bytes(typed), read.count == symbols, read.bytes.count == keyLength + checkLength,
            read.leftover == 0
        else { return nil }
        let key = Data(read.bytes.prefix(keyLength))
        return Array(read.bytes.suffix(checkLength)) == check(key) ? key : nil
    }

    private static func check(_ key: Data) -> [UInt8] {
        var hash = SHA256()
        hash.update(data: Data("sunset.recovery.v1".utf8))
        hash.update(data: key)
        return Array(hash.finalize().prefix(checkLength))
    }
}
