/// Where the values of a JSON5 document are in its bytes: enough structure to replace a value or add a member without touching the rest. Comments, single-quoted
/// strings, bare keys and trailing commas are understood; numbers and literals are only skipped over.
struct JSONSpans {
    struct Member {
        var key: String
        var keyStart: Int
        var value: JSONSpans
    }

    /// The bytes of the value, from its first to one past its last.
    var range: Range<Int>
    var members: [Member] = []
    var isObject = false

    static func parse(_ bytes: [UInt8]) -> JSONSpans? {
        var scanner = Scanner(bytes: bytes)
        scanner.skipSpace()
        guard let root = scanner.value(depth: 0) else { return nil }
        scanner.skipSpace()
        return scanner.index == bytes.count ? root : nil
    }

    private struct Scanner {
        let bytes: [UInt8]
        var index = 0

        init(bytes: [UInt8]) { self.bytes = bytes }

        mutating func skipSpace() {
            while index < bytes.count {
                let byte = bytes[index]
                if byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
                    index += 1
                } else if byte == 0x2F, index + 1 < bytes.count, bytes[index + 1] == 0x2F {
                    while index < bytes.count, bytes[index] != 0x0A { index += 1 }
                } else if byte == 0x2F, index + 1 < bytes.count, bytes[index + 1] == 0x2A {
                    index += 2
                    while index + 1 < bytes.count, !(bytes[index] == 0x2A && bytes[index + 1] == 0x2F) { index += 1 }
                    index = min(index + 2, bytes.count)
                } else {
                    return
                }
            }
        }

        mutating func value(depth: Int) -> JSONSpans? {
            guard index < bytes.count, depth < 64 else { return nil }
            let start = index
            switch bytes[index] {
                case 0x7B: return object(start: start, depth: depth)
                case 0x5B: return array(start: start, depth: depth)
                case 0x22, 0x27:
                    guard string() != nil else { return nil }
                    return JSONSpans(range: start ..< index)
                default:
                    // A number or a literal: up to a delimiter.
                    while index < bytes.count, !Self.delimiters.contains(bytes[index]) { index += 1 }
                    return index > start ? JSONSpans(range: start ..< index) : nil
            }
        }

        private static let delimiters: Set<UInt8> = [0x2C, 0x7D, 0x5D, 0x20, 0x09, 0x0A, 0x0D, 0x3A, 0x2F]

        /// A quoted string; returns its decoded text (escapes other than the simple ones are kept as written: keys are plain).
        private mutating func string() -> String? {
            let quote = bytes[index]
            index += 1
            var out: [UInt8] = []
            while index < bytes.count {
                let byte = bytes[index]
                if byte == quote {
                    index += 1
                    return String(decoding: out, as: UTF8.self)
                }
                if byte == 0x5C, index + 1 < bytes.count {
                    out.append(bytes[index + 1])
                    index += 2
                    continue
                }
                out.append(byte)
                index += 1
            }
            return nil
        }

        private mutating func object(start: Int, depth: Int) -> JSONSpans? {
            index += 1
            var result = JSONSpans(range: start ..< start, isObject: true)
            while true {
                skipSpace()
                guard index < bytes.count else { return nil }
                if bytes[index] == 0x7D {
                    index += 1
                    result.range = start ..< index
                    return result
                }
                let keyStart = index
                let key: String
                if bytes[index] == 0x22 || bytes[index] == 0x27 {
                    guard let text = string() else { return nil }
                    key = text
                } else {
                    while index < bytes.count, !Self.delimiters.contains(bytes[index]) { index += 1 }
                    guard index > keyStart else { return nil }
                    key = String(decoding: bytes[keyStart ..< index], as: UTF8.self)
                }
                skipSpace()
                guard index < bytes.count, bytes[index] == 0x3A else { return nil }
                index += 1
                skipSpace()
                guard let child = value(depth: depth + 1) else { return nil }
                result.members.append(Member(key: key, keyStart: keyStart, value: child))
                skipSpace()
                if index < bytes.count, bytes[index] == 0x2C { index += 1 }
            }
        }

        private mutating func array(start: Int, depth: Int) -> JSONSpans? {
            index += 1
            while true {
                skipSpace()
                guard index < bytes.count else { return nil }
                if bytes[index] == 0x5D {
                    index += 1
                    return JSONSpans(range: start ..< index)
                }
                guard value(depth: depth + 1) != nil else { return nil }
                skipSpace()
                if index < bytes.count, bytes[index] == 0x2C { index += 1 }
            }
        }
    }
}
