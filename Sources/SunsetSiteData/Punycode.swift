/// Punycode's decoding (RFC 3492): the label after `xn--` to its Unicode text, for matching the Public Suffix List's
/// Unicode rules against the punycode hosts URLs carry.
enum Punycode {
    private static let base = 36
    private static let tmin = 1
    private static let tmax = 26

    /// The Unicode text of an encoded label; nil when it is not valid punycode.
    /// - Complexity: O(n²) in the label's length (an insertion each), for labels of at most 63 characters.
    static func decode(_ encoded: Substring) -> String? {
        let input = Array(encoded.unicodeScalars)
        var output: [Unicode.Scalar] = []
        var position = 0
        if let delimiter = input.lastIndex(of: "-") {
            guard input[..<delimiter].allSatisfy(\.isASCII) else { return nil }
            output = Array(input[..<delimiter])
            position = delimiter + 1
        }
        var code = 128
        var index = 0
        var bias = 72
        while position < input.count {
            let before = index
            var weight = 1
            var step = base
            while true {
                guard position < input.count, let digit = digit(input[position]) else { return nil }
                position += 1
                index += digit * weight
                let threshold = step <= bias ? tmin : (step >= bias + tmax ? tmax : step - bias)
                if digit < threshold { break }
                weight *= base - threshold
                step += base
            }
            bias = adapt(index - before, count: output.count + 1, first: before == 0)
            code += index / (output.count + 1)
            index %= output.count + 1
            guard let scalar = Unicode.Scalar(code) else { return nil }
            output.insert(scalar, at: index)
            index += 1
        }
        return String(String.UnicodeScalarView(output))
    }

    private static func digit(_ scalar: Unicode.Scalar) -> Int? {
        switch scalar.value {
            case 0x61 ... 0x7A: Int(scalar.value - 0x61)
            case 0x41 ... 0x5A: Int(scalar.value - 0x41)
            case 0x30 ... 0x39: Int(scalar.value - 0x30) + 26
            default: nil
        }
    }

    private static func adapt(_ delta: Int, count: Int, first: Bool) -> Int {
        var delta = first ? delta / 700 : delta / 2
        delta += delta / count
        var step = 0
        while delta > ((base - tmin) * tmax) / 2 {
            delta /= base - tmin
            step += base
        }
        return step + (base - tmin + 1) * delta / (delta + 38)
    }
}
