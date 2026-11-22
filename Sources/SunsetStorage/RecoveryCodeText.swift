import CryptoKit
package import Foundation

/// The key in a form to write down (R12): its 32 bytes and two bytes that check them, in Crockford's base 32 (no I, L, O or U,
/// so nothing is mistaken for a digit), as eleven groups of five. Read back whatever the case, with spaces or dashes, and with
/// O, I and L taken for the digits they look like; a mistyped code fails the check.
package enum RecoveryCodeText {
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let keyLength = 32
    private static let checkLength = 2
    /// Symbols in a code: 34 bytes, five bits a symbol.
    static let symbols = ((keyLength + checkLength) * 8 + 4) / 5

    package static func encode(_ key: Data) -> String {
        let bytes = Array(key) + check(key)
        var symbols: [Character] = []
        var buffer = 0
        var bits = 0
        for byte in bytes {
            buffer = (buffer << 8) | Int(byte)
            bits += 8
            while bits >= 5 {
                bits -= 5
                symbols.append(alphabet[(buffer >> bits) & 31])
            }
        }
        if bits > 0 { symbols.append(alphabet[(buffer << (5 - bits)) & 31]) }
        return stride(from: 0, to: symbols.count, by: 5)
            .map { String(symbols[$0 ..< min($0 + 5, symbols.count)]) }
            .joined(separator: "-")
    }

    /// The key a code holds; nil when it is not a code, or its check fails.
    package static func decode(_ code: String) -> Data? {
        var bytes: [UInt8] = []
        var buffer = 0
        var bits = 0
        var count = 0
        for character in code.uppercased() where character != "-" && !character.isWhitespace {
            let symbol: Character =
                switch character {
                    case "O": "0"
                    case "I", "L": "1"
                    default: character
                }
            guard let value = alphabet.firstIndex(of: symbol) else { return nil }
            count += 1
            buffer = ((buffer << 5) | value) & 0xFFFF
            bits += 5
            if bits >= 8 {
                bits -= 8
                bytes.append(UInt8((buffer >> bits) & 0xFF))
            }
        }
        // The bits left over after the last byte are padding: zero in a code we made.
        guard count == symbols, bytes.count == keyLength + checkLength, buffer & ((1 << bits) - 1) == 0 else {
            return nil
        }
        let key = Data(bytes.prefix(keyLength))
        return Array(bytes.suffix(checkLength)) == check(key) ? key : nil
    }

    private static func check(_ key: Data) -> [UInt8] {
        var hash = SHA256()
        hash.update(data: Data("sunset.recovery.v1".utf8))
        hash.update(data: key)
        return Array(hash.finalize().prefix(checkLength))
    }
}
