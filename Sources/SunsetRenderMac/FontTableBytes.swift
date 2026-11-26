/// A font table's bytes, read big-endian with every offset checked: a table from a font file is untrusted, and a bad
/// offset is `Malformed`, never a trap. Used to read substitution tables (`SubstitutionReach`).
struct FontTableBytes: Sendable {
    /// An offset or count outside the table.
    struct Malformed: Error {}

    let bytes: [UInt8]

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// The `width` bytes at `offset`, when all are inside the table.
    private func span(_ offset: Int, _ width: Int) throws(Malformed) -> ArraySlice<UInt8> {
        guard offset >= 0, offset <= bytes.count - width else { throw Malformed() }
        return bytes[offset ..< offset + width]
    }

    func u16(_ offset: Int) throws(Malformed) -> Int {
        try span(offset, 2).reduce(0) { $0 << 8 | Int($1) }
    }

    func u32(_ offset: Int) throws(Malformed) -> Int {
        try span(offset, 4).reduce(0) { $0 << 8 | Int($1) }
    }

    /// The four-letter tag at `offset`.
    func tag(_ offset: Int) throws(Malformed) -> String {
        String(decoding: try span(offset, 4), as: UTF8.self)
    }

    /// Value `index` of the array of 16-bit values whose count is at `array`, the values right after it.
    func element(_ array: Int, _ index: Int) throws(Malformed) -> Int {
        guard index < (try u16(array)) else { throw Malformed() }
        return try u16(array + 2 + 2 * index)
    }

    /// `count` 16-bit values from `offset`.
    func u16s(_ offset: Int, count: Int) throws(Malformed) -> [Int] {
        guard count >= 0, offset >= 0, offset <= bytes.count - 2 * count else { throw Malformed() }
        return (0 ..< count).map { Int(bytes[offset + 2 * $0]) << 8 | Int(bytes[offset + 2 * $0 + 1]) }
    }

    /// Where an OpenType Offset16 at `field` points, from `base`; nil for a null offset (0).
    func offset16(_ field: Int, from base: Int) throws(Malformed) -> Int? {
        let value = try u16(field)
        return value == 0 ? nil : base + value
    }
}
