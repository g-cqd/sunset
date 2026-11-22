/// Bytes written five bits a symbol over a 32-symbol alphabet, most significant bit first: the packing base 32 (RFC 4648)
/// and Crockford's share. What a symbol may be typed as, and what the text looks like, is each user's.
package struct FiveBitText: Sendable {
    package let alphabet: [Character]

    package init(_ alphabet: String) {
        self.alphabet = Array(alphabet)
    }

    /// The symbols of `bytes`, the last one padded with zero bits.
    package func symbols(_ bytes: some Sequence<UInt8>) -> [Character] {
        var symbols: [Character] = []
        var buffer = 0
        var bits = 0
        for byte in bytes {
            buffer = ((buffer << 8) | Int(byte)) & 0xFFFF
            bits += 8
            while bits >= 5 {
                bits -= 5
                symbols.append(alphabet[(buffer >> bits) & 31])
            }
        }
        if bits > 0 { symbols.append(alphabet[(buffer << (5 - bits)) & 31]) }
        return symbols
    }

    /// The bytes `symbols` hold, and the bits left over after the last whole byte (zero in text that was written whole);
    /// nil when one is not of the alphabet.
    package func bytes(_ symbols: some Sequence<Character>) -> (bytes: [UInt8], leftover: Int, count: Int)? {
        var bytes: [UInt8] = []
        var buffer = 0
        var bits = 0
        var count = 0
        for symbol in symbols {
            guard let value = alphabet.firstIndex(of: symbol) else { return nil }
            count += 1
            buffer = ((buffer << 5) | value) & 0xFFFF
            bits += 5
            if bits >= 8 {
                bits -= 8
                bytes.append(UInt8((buffer >> bits) & 0xFF))
            }
        }
        return (bytes, buffer & ((1 << bits) - 1), count)
    }
}
