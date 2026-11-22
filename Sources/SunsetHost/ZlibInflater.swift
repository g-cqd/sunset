internal import Compression
public import SunsetCore

/// Inflates the zlib streams of compressed images (`o=z`, ADR-0117, roadmap 0010 D) with Apple's Compression framework: the
/// two-byte zlib header checked, the deflate data inflated into at most `limit` bytes (one more is room to see it would not
/// fit), and the Adler-32 checksum at its end checked against what came out. Compression stops quietly at the end of a
/// stream cut short and returns what it had; the checksum is what tells.
public struct ZlibInflater: Inflater {
    public init() {}

    public func inflate(_ data: [UInt8], limit: Int) -> [UInt8]? {
        guard data.count >= 6, limit >= 0 else { return nil }
        // CMF and FLG: deflate (8) with a window of at most 32 KiB, no preset dictionary, the pair a multiple of 31.
        let (method, flags) = (data[0], data[1])
        guard method & 0x0F == 8, method >> 4 <= 7, flags & 0x20 == 0, (Int(method) << 8 | Int(flags)) % 31 == 0 else {
            return nil
        }
        let out = CompressionDecode.decode(data[2 ..< data.count - 4], capacity: limit + 1, COMPRESSION_ZLIB)
        guard out.count <= limit else { return nil }
        let stored = data.suffix(4).reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
        return Self.adler32(out) == stored ? out : nil
    }

    /// Adler-32 of `bytes`, summed in runs of 5,552 bytes (the most before the sums could overflow 32 bits).
    static func adler32(_ bytes: [UInt8]) -> UInt32 {
        var (a, b): (UInt32, UInt32) = (1, 0)
        var start = 0
        while start < bytes.count {
            let end = min(start + 5_552, bytes.count)
            for index in start ..< end {
                a &+= UInt32(bytes[index])
                b &+= a
            }
            (a, b) = (a % 65_521, b % 65_521)
            start = end
        }
        return b << 16 | a
    }
}
