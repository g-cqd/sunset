/// A reply built on the stack and committed whole or not at all.
struct ReplyWriter {
    private(set) var storage = InlineArray<64, UInt8>(repeating: 0)
    private(set) var count = 0
    private(set) var overflowed = false

    mutating func byte(_ value: UInt8) {
        guard count < 64 else {
            overflowed = true
            return
        }
        storage[count] = value
        count += 1
    }

    mutating func text(_ string: StaticString) {
        string.withUTF8Buffer { buffer in
            for value in buffer { byte(value) }
        }
    }

    /// An 8-bit value as the four hex digits of the 16-bit component X colour queries use (each digit pair repeated).
    mutating func hex16(_ value: UInt8) {
        let digits: StaticString = "0123456789abcdef"
        digits.withUTF8Buffer { table in
            let high = table[Int(value >> 4)]
            let low = table[Int(value & 15)]
            byte(high)
            byte(low)
            byte(high)
            byte(low)
        }
    }

    mutating func number(_ value: Int) {
        var digits = InlineArray<20, UInt8>(repeating: 0)
        var length = 0
        var rest = max(0, value)
        repeat {
            digits[length] = UInt8(0x30 + rest % 10)
            length += 1
            rest /= 10
        } while rest > 0
        while length > 0 {
            length -= 1
            byte(digits[length])
        }
    }
}
