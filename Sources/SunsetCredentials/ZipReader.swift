import Foundation

/// The files of a zip archive, read in memory (PKWARE APPNOTE: its central directory, each file stored or DEFLATE'd):
/// a 1Password export (`.1pux`). Zip64, encryption and other methods are refused; every size and offset is checked
/// against the archive, and the files inflated together are bounded.
enum ZipReader {
    /// The most bytes an archive's files may inflate to, together.
    static let largest = 1 << 30

    /// The archive's files by name; nil when it is not a zip this reads.
    static func files(_ data: Data) -> [String: Data]? {
        let bytes = [UInt8](data)
        guard let end = endOfDirectory(bytes) else { return nil }
        var reader = ByteReader(bytes)
        var files: [String: Data] = [:]
        var total = 0
        do {
            _ = try reader.take(end.offset)
            for _ in 0 ..< end.count {
                guard try reader.uint32() == 0x0201_4B50 else { return nil }
                _ = try reader.take(4)
                let flags = try reader.uint16()
                let method = try reader.uint16()
                _ = try reader.take(4)
                let crc = try reader.uint32()
                let packed = Int(try reader.uint32())
                let size = Int(try reader.uint32())
                let nameLength = Int(try reader.uint16())
                let extra = Int(try reader.uint16())
                let comment = Int(try reader.uint16())
                _ = try reader.take(8)
                let local = Int(try reader.uint32())
                let name = String(decoding: try reader.take(nameLength), as: UTF8.self)
                _ = try reader.take(extra + comment)
                guard flags & 1 == 0, packed != 0xFFFF_FFFF, size != 0xFFFF_FFFF, local != 0xFFFF_FFFF else {
                    return nil
                }
                total += size
                guard total <= largest else { return nil }
                if name.hasSuffix("/") { continue }
                let file = try contents(bytes, at: local, packed: packed, size: size, method: method)
                // What was inflated is what was zipped: its CRC-32 is the directory's.
                guard CRC32.of(file) == crc else { return nil }
                files[name] = Data(file)
            }
        } catch {
            return nil
        }
        return files
    }

    /// Where the central directory starts, and how many files it lists: the end record is in the archive's last 64 KiB.
    private static func endOfDirectory(_ bytes: [UInt8]) -> (offset: Int, count: Int)? {
        guard bytes.count >= 22 else { return nil }
        let lowest = max(0, bytes.count - 22 - 0xFFFF)
        for start in stride(from: bytes.count - 22, through: lowest, by: -1)
        where bytes[start] == 0x50 && bytes[start + 1] == 0x4B && bytes[start + 2] == 5 && bytes[start + 3] == 6 {
            var reader = ByteReader(Array(bytes[start ..< bytes.count]))
            guard (try? reader.take(10)) != nil, let count = try? reader.uint16(), (try? reader.take(4)) != nil,
                let offset = try? reader.uint32(), Int(offset) < bytes.count
            else { return nil }
            return (Int(offset), Int(count))
        }
        return nil
    }

    /// A file's bytes from its local header: stored, or inflated to exactly its size.
    private static func contents(_ bytes: [UInt8], at local: Int, packed: Int, size: Int, method: UInt16)
        throws(KeePassFile.Failure) -> [UInt8]
    {
        guard local <= bytes.count else { throw .damaged }
        var reader = ByteReader(Array(bytes[local...]))
        guard try reader.uint32() == 0x0403_4B50 else { throw .damaged }
        _ = try reader.take(22)
        let name = Int(try reader.uint16())
        let extra = Int(try reader.uint16())
        _ = try reader.take(name + extra)
        let data = try reader.take(packed)
        switch method {
            case 0: return data
            case 8:
                let inflated = try Inflate.raw(data, largest: size)
                guard inflated.count == size else { throw .damaged }
                return inflated
            default: throw .damaged
        }
    }
}
