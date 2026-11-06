/// The numeric parameters of a control sequence, held inline (no allocation). A missing parameter reads as 0, which every consumer treats as "default".
/// Values saturate at 65535. A `:` introduces a sub-parameter: it is stored as one more parameter, flagged in `subParameterMask`.
public struct Parameters: Sendable, Equatable {
    /// How many parameters a sequence may carry; a longer one is ignored whole (a defined outcome, not a truncation).
    public static let capacity = 32

    public private(set) var count = 0
    /// Bit `i` is set when parameter `i` followed a `:` (a sub-parameter of parameter `i - 1`).
    public private(set) var subParameterMask: UInt32 = 0
    private var storage = InlineArray<32, UInt16>(repeating: 0)

    public init() {}

    /// The parameter at `index`, or `fallback` when absent or 0.
    public func value(_ index: Int, default fallback: Int) -> Int {
        guard index < count, storage[index] != 0 else { return fallback }
        return Int(storage[index])
    }

    /// The parameter at `index` exactly as sent (0 when absent).
    public subscript(index: Int) -> Int { index < count ? Int(storage[index]) : 0 }

    public func isSubParameter(_ index: Int) -> Bool { index < count && subParameterMask & (1 << UInt32(index)) != 0 }

    /// Starts a new parameter (value 0). False when full.
    mutating func begin(subParameter: Bool) -> Bool {
        guard count < Self.capacity else { return false }
        storage[count] = 0
        if subParameter { subParameterMask |= 1 << UInt32(count) }
        count += 1
        return true
    }

    /// Appends a decimal digit to the parameter being built, saturating at 65535.
    mutating func appendDigit(_ digit: UInt8) {
        let next = Int(storage[count - 1]) * 10 + Int(digit)
        storage[count - 1] = next > 65535 ? 65535 : UInt16(next)
    }

    mutating func reset() {
        count = 0
        subParameterMask = 0
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count, lhs.subParameterMask == rhs.subParameterMask else { return false }
        for index in 0 ..< lhs.count where lhs.storage[index] != rhs.storage[index] { return false }
        return true
    }
}

/// Up to two intermediate bytes (0x20...0x2F) of an escape or control sequence, packed.
public struct Intermediates: Sendable, Equatable {
    public private(set) var count = 0
    public private(set) var first: UInt8 = 0
    public private(set) var second: UInt8 = 0

    public init() {}

    public init(_ bytes: UInt8...) {
        for byte in bytes { _ = append(byte) }
    }

    mutating func append(_ byte: UInt8) -> Bool {
        switch count {
            case 0: first = byte
            case 1: second = byte
            default: return false
        }
        count += 1
        return true
    }

    mutating func reset() {
        count = 0
        first = 0
        second = 0
    }
}
