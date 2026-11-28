/// Little-endian reading of a file's bytes, every read bounded.
struct ByteReader {
    private let bytes: [UInt8]
    private(set) var offset = 0

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    mutating func take(_ count: Int) throws(KeePassFile.Failure) -> [UInt8] {
        guard count >= 0, count <= bytes.count - offset else { throw .damaged }
        defer { offset += count }
        return Array(bytes[offset ..< offset + count])
    }

    mutating func uint16() throws(KeePassFile.Failure) -> UInt16 {
        try take(2).reversed().reduce(0) { $0 << 8 | UInt16($1) }
    }

    mutating func uint32() throws(KeePassFile.Failure) -> UInt32 {
        try take(4).reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }
}
