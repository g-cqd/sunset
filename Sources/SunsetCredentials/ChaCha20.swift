/// ChaCha20 as RFC 8439 has it (a 256-bit key, a 96-bit nonce, a 32-bit block counter), the stream alone: KeePass's
/// database cipher and the stream that hides its protected values (KDBX 4). CryptoKit has it only with Poly1305.
struct ChaCha20 {
    private var state: [UInt32]
    private var block: [UInt8] = []
    private var used = 64

    /// nil unless the key is 32 bytes and the nonce 12.
    init?(key: [UInt8], nonce: [UInt8], counter: UInt32 = 0) {
        guard key.count == 32, nonce.count == 12 else { return nil }
        // Each word little-endian: its last byte the most significant.
        func word(_ bytes: [UInt8], _ at: Int) -> UInt32 {
            bytes[at ..< at + 4].reversed().reduce(0) { $0 << 8 | UInt32($1) }
        }
        state = [0x6170_7865, 0x3320_646E, 0x7962_2D32, 0x6B20_6574]
        state += (0 ..< 8).map { word(key, $0 * 4) }
        state.append(counter)
        state += (0 ..< 3).map { word(nonce, $0 * 4) }
    }

    /// `bytes` XORed with the next bytes of the stream.
    mutating func apply(_ bytes: [UInt8]) -> [UInt8] {
        var out = bytes
        for index in out.indices {
            if used == 64 { nextBlock() }
            out[index] ^= block[used]
            used += 1
        }
        return out
    }

    private mutating func nextBlock() {
        var working = state
        func quarter(_ a: Int, _ b: Int, _ c: Int, _ d: Int) {
            working[a] &+= working[b]
            working[d] ^= working[a]
            working[d] = working[d] << 16 | working[d] >> 16
            working[c] &+= working[d]
            working[b] ^= working[c]
            working[b] = working[b] << 12 | working[b] >> 20
            working[a] &+= working[b]
            working[d] ^= working[a]
            working[d] = working[d] << 8 | working[d] >> 24
            working[c] &+= working[d]
            working[b] ^= working[c]
            working[b] = working[b] << 7 | working[b] >> 25
        }
        for _ in 0 ..< 10 {
            quarter(0, 4, 8, 12)
            quarter(1, 5, 9, 13)
            quarter(2, 6, 10, 14)
            quarter(3, 7, 11, 15)
            quarter(0, 5, 10, 15)
            quarter(1, 6, 11, 12)
            quarter(2, 7, 8, 13)
            quarter(3, 4, 9, 14)
        }
        block = (0 ..< 16)
            .flatMap { index -> [UInt8] in
                let value = working[index] &+ state[index]
                return [
                    UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8),
                    UInt8(truncatingIfNeeded: value >> 16), UInt8(truncatingIfNeeded: value >> 24)
                ]
            }
        state[12] &+= 1
        used = 0
    }
}
