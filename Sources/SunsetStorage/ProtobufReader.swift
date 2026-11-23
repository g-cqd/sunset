import Foundation

/// The protobuf wire format, as far as an import needs it: varints and length-delimited fields, each bounded by what is
/// left (a cut or altered payload is refused, never read past its end). Groups and fixed-width fields are skipped. Read for
/// Google Authenticator's export and Chrome's extension packages.
package struct ProtobufReader {
    package struct Invalid: Error {}

    /// A field: its number, and its varint or its bytes.
    package enum Value {
        case varint(UInt64)
        case bytes([UInt8])
    }

    private let bytes: [UInt8]
    private var at = 0

    package init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// Every field, in order.
    package mutating func fields() throws(Invalid) -> [(number: UInt64, value: Value)] {
        var fields: [(UInt64, Value)] = []
        while at < bytes.count {
            let key = try varint()
            let number = key >> 3
            switch key & 7 {
                case 0: fields.append((number, .varint(try varint())))
                case 2:
                    let length = Int(try varint())
                    guard length >= 0, at + length <= bytes.count else { throw Invalid() }
                    fields.append((number, .bytes(Array(bytes[at ..< at + length]))))
                    at += length
                case 1: try skip(8)
                case 5: try skip(4)
                default: throw Invalid()
            }
        }
        return fields
    }

    private mutating func varint() throws(Invalid) -> UInt64 {
        var value: UInt64 = 0
        for shift in stride(from: 0, to: 64, by: 7) {
            guard at < bytes.count else { throw Invalid() }
            let byte = bytes[at]
            at += 1
            value |= UInt64(byte & 0x7F) << UInt64(shift)
            if byte & 0x80 == 0 { return value }
        }
        throw Invalid()
    }

    private mutating func skip(_ count: Int) throws(Invalid) {
        guard at + count <= bytes.count else { throw Invalid() }
        at += count
    }
}
