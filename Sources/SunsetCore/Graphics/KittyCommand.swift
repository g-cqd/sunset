/// A kitty graphics command (`ESC _ G control ; payload ESC \`): its control data, `key=value` pairs separated by commas,
/// each key one letter and each value a number or one letter; and its payload, base64. Read once, bounded: a value is at
/// most ten digits, an unknown key is kept and ignored.
struct KittyCommand: Sendable {
    private var values: [UInt8: Int] = [:]
    /// The base64 payload, as sent.
    let payload: ArraySlice<UInt8>

    /// Reads the command after its `G`; nil when its control data does not read.
    init?(_ bytes: ArraySlice<UInt8>) {
        let end = bytes.firstIndex(of: UInt8(ascii: ";")) ?? bytes.endIndex
        payload = end < bytes.endIndex ? bytes[(end + 1)...] : []
        for pair in bytes[..<end].split(separator: UInt8(ascii: ","), omittingEmptySubsequences: true) {
            guard pair.count >= 3, let key = pair.first, pair[pair.startIndex + 1] == UInt8(ascii: "=") else {
                return nil
            }
            let value = pair.dropFirst(2)
            if let number = Self.number(value) {
                values[key] = number
            } else if value.count == 1, let letter = value.first {
                values[key] = Int(letter)
            } else {
                return nil
            }
        }
    }

    /// A number's value (`i`, `s`, `f`, …); `fallback` when absent.
    func int(_ key: Unicode.Scalar, or fallback: Int = 0) -> Int {
        values[UInt8(key.value)] ?? fallback
    }

    /// A letter's value (`a`, `t`, `d`, `o`); `fallback` when absent.
    func letter(_ key: Unicode.Scalar, or fallback: Unicode.Scalar) -> UInt8 {
        values[UInt8(key.value)].map { UInt8(truncatingIfNeeded: $0) } ?? UInt8(fallback.value)
    }

    /// A decimal value, perhaps negative, of at most ten digits.
    private static func number(_ text: ArraySlice<UInt8>) -> Int? {
        let negative = text.first == UInt8(ascii: "-")
        let digits = negative ? text.dropFirst() : text
        guard !digits.isEmpty, digits.count <= 10, digits.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }) else { return nil }
        let value = digits.reduce(0) { $0 * 10 + Int($1 - 0x30) }
        return negative ? -value : value
    }
}
