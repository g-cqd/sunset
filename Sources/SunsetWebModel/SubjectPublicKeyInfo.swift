internal import Foundation

/// A DER SubjectPublicKeyInfo read as far as an RSA key needs: the PKCS #1 key inside its bit string, which is what the
/// Security framework takes. Lengths are checked against what is left; anything else is nil.
enum SubjectPublicKeyInfo {
    /// rsaEncryption's object identifier (1.2.840.113549.1.1.1).
    private static let rsaEncryption: [UInt8] = [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01]

    static func rsaKey(_ der: Data) -> Data? {
        let bytes = [UInt8](der)
        guard let outer = element(bytes, at: 0, tag: 0x30) else { return nil }
        guard let algorithm = element(bytes, at: outer.body.lowerBound, tag: 0x30),
            bytes[algorithm.body].starts(with: rsaEncryption),
            let key = element(bytes, at: algorithm.body.upperBound, tag: 0x03),
            key.body.count > 1, bytes[key.body.lowerBound] == 0
        else { return nil }
        return Data(bytes[key.body.lowerBound + 1 ..< key.body.upperBound])
    }

    /// The element with `tag` at `at`: where its body is.
    private static func element(_ bytes: [UInt8], at: Int, tag: UInt8) -> (body: Range<Int>, end: Int)? {
        guard at + 2 <= bytes.count, bytes[at] == tag else { return nil }
        var length = Int(bytes[at + 1])
        var start = at + 2
        if length & 0x80 != 0 {
            let count = length & 0x7F
            guard (1 ... 3).contains(count), start + count <= bytes.count else { return nil }
            length = bytes[start ..< start + count].reduce(0) { $0 << 8 | Int($1) }
            start += count
        }
        guard start + length <= bytes.count else { return nil }
        return (start ..< start + length, start + length)
    }
}
