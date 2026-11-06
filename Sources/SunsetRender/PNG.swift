/// A minimal PNG writer for surfaces: 8-bit RGBA, no filtering and stored (uncompressed) deflate blocks. Large files, but nothing to get wrong, no
/// dependency, and every viewer reads it: for looking at what the renderer drew.
public enum PNG {
    public static func encode(_ surface: Surface) -> [UInt8] {
        var raw: [UInt8] = []
        raw.reserveCapacity((surface.width * 4 + 1) * surface.height)
        let bytes = surface.rgbaBytes
        for row in 0 ..< surface.height {
            raw.append(0)  // filter: none
            raw.append(contentsOf: bytes[row * surface.width * 4 ..< (row + 1) * surface.width * 4])
        }
        var out: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        var header: [UInt8] = []
        header.append(contentsOf: bigEndian(UInt32(surface.width)))
        header.append(contentsOf: bigEndian(UInt32(surface.height)))
        header.append(contentsOf: [8, 6, 0, 0, 0])  // 8 bits, RGBA, deflate, no filter method, no interlace
        chunk("IHDR", header, into: &out)
        chunk("IDAT", zlibStored(raw), into: &out)
        chunk("IEND", [], into: &out)
        return out
    }

    static func bigEndian(_ value: UInt32) -> [UInt8] {
        [
            UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)
        ]
    }

    private static func chunk(_ type: String, _ data: [UInt8], into out: inout [UInt8]) {
        out.append(contentsOf: bigEndian(UInt32(data.count)))
        let body = Array(type.utf8) + data
        out.append(contentsOf: body)
        out.append(contentsOf: bigEndian(crc32(body)))
    }

    /// zlib stream of stored blocks (at most 65 535 bytes each) with its Adler-32 trailer.
    static func zlibStored(_ data: [UInt8]) -> [UInt8] {
        var out: [UInt8] = [0x78, 0x01]
        var offset = 0
        repeat {
            let length = min(65535, data.count - offset)
            let isLast = offset + length >= data.count
            out.append(isLast ? 1 : 0)
            out.append(UInt8(length & 0xFF))
            out.append(UInt8(length >> 8))
            out.append(UInt8(~length & 0xFF))
            out.append(UInt8((~length >> 8) & 0xFF))
            out.append(contentsOf: data[offset ..< offset + length])
            offset += length
        } while offset < data.count
        out.append(contentsOf: bigEndian(adler32(data)))
        return out
    }

    static func adler32(_ data: [UInt8]) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        for byte in data {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
        return b << 16 | a
    }

    private static let crcTable: [UInt32] = (0 ..< 256)
        .map { index in
            var value = UInt32(index)
            for _ in 0 ..< 8 { value = value & 1 != 0 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1 }
            return value
        }

    static func crc32(_ data: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data { crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8) }
        return ~crc
    }
}
