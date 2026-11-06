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
