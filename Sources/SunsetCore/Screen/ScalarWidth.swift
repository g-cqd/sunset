internal import TerminalKitText

/// The display width of a single scalar, by table. The library measures a `Character`, and making one from a scalar (a string, a grapheme walk) was more than a
/// third of the cost of printing non-ASCII text (sampled: `displayWidth(of:)` and string construction ahead of the parser itself). The width of a scalar alone
/// does not depend on its neighbours, so it is looked up in a table, built from the library's own answers the first time a scalar of that range is seen
/// (about a millisecond for 64 K scalars, once per process); the tests compare every scalar with the library.
enum ScalarWidth {
    /// Below this every printable scalar is one column (the library's own shortcut), and U+0000 is none.
    private static let narrowLimit: UInt32 = 0x300

    private static let basic: [UInt8] = table(from: 0, count: 0x10000)
    private static let supplementary: [UInt8] = table(from: 0x10000, count: 0x10000)

    static func of(_ scalar: Unicode.Scalar) -> Int {
        let value = scalar.value
        if value < narrowLimit { return value == 0 ? 0 : 1 }
        if value < 0x10000 { return Int(basic[Int(value)]) }
        if value < 0x20000 { return Int(supplementary[Int(value - 0x10000)]) }
        return UnicodeWidth.displayWidth(of: Character(scalar))
    }

    private static func table(from first: UInt32, count: Int) -> [UInt8] {
        [UInt8](unsafeUninitializedCapacity: count) { buffer, filled in
            for offset in 0 ..< count {
                let width =
                    Unicode.Scalar(first + UInt32(offset)).map { UnicodeWidth.displayWidth(of: Character($0)) } ?? 1
                buffer[offset] = UInt8(truncatingIfNeeded: width)
            }
            filled = count
        }
    }
}
