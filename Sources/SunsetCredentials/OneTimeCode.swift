import CryptoKit
public import Foundation

/// One-time codes (roadmap 0093 A): HOTP (RFC 4226), TOTP (RFC 6238) with SHA-1, SHA-256 or SHA-512, and Steam Guard's
/// five characters, all from the same HMAC and its dynamic truncation. Checked against the RFCs' appendices.
public enum OneTimeCode {
    public enum Algorithm: String, Sendable, Equatable, Codable { case sha1, sha256, sha512 }

    /// A code's shape: 6 to 10 digits (RFC 4226 asks for at least 6; 10 is all a 31-bit value holds), a period of at
    /// least a second.
    public struct Parameters: Equatable, Sendable {
        public var digits: Int
        public var period: Int

        public init(digits: Int, period: Int) {
            self.digits = digits
            self.period = period
        }

        public var isValid: Bool {
            (6 ... 10).contains(digits) && period > 0
        }
    }

    /// The HOTP code for `counter`, `digits` long, zero-padded.
    public static func hotp(secret: Data, counter: UInt64, digits: Int, algorithm: Algorithm) -> String {
        let value = truncated(secret: secret, counter: counter, algorithm: algorithm)
        let modulus = (0 ..< digits).reduce(UInt64(1)) { power, _ in power * 10 }
        let code = String(UInt64(value) % modulus)
        return String(repeating: "0", count: max(digits - code.count, 0)) + code
    }

    /// The TOTP code at `at`: HOTP over the periods since 1970.
    public static func totp(secret: Data, at: Date, period: Int, digits: Int, algorithm: Algorithm) -> String {
        hotp(secret: secret, counter: counter(at: at, period: period), digits: digits, algorithm: algorithm)
    }

    /// Steam Guard's code: the truncated value written base 26 in its own alphabet, five characters, least significant
    /// first. Steam's counter is the TOTP one, with a period of 30 seconds.
    public static func steam(secret: Data, counter: UInt64) -> String {
        let alphabet = Array("23456789BCDFGHJKMNPQRTVWXY")
        var value = Int(truncated(secret: secret, counter: counter, algorithm: .sha1))
        var code = ""
        for _ in 0 ..< 5 {
            code.append(alphabet[value % alphabet.count])
            value /= alphabet.count
        }
        return code
    }

    /// The TOTP counter at `at`.
    public static func counter(at: Date, period: Int) -> UInt64 {
        UInt64(max(at.timeIntervalSince1970, 0)) / UInt64(max(period, 1))
    }

    /// The whole seconds before the code at `at` changes.
    public static func secondsLeft(at: Date, period: Int) -> Int {
        let period = max(period, 1)
        return period - Int(UInt64(max(at.timeIntervalSince1970, 0)) % UInt64(period))
    }

    /// RFC 4226's dynamic truncation of the HMAC of `counter`: 31 bits.
    private static func truncated(secret: Data, counter: UInt64, algorithm: Algorithm) -> UInt32 {
        let message = withUnsafeBytes(of: counter.bigEndian) { Data($0) }
        let key = SymmetricKey(data: secret)
        let mac: [UInt8] =
            switch algorithm {
                case .sha1: Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key))
                case .sha256: Array(HMAC<SHA256>.authenticationCode(for: message, using: key))
                case .sha512: Array(HMAC<SHA512>.authenticationCode(for: message, using: key))
            }
        let offset = Int(mac[mac.count - 1] & 0x0F)
        return mac[offset ..< offset + 4].reduce(UInt32(0)) { $0 << 8 | UInt32($1) } & 0x7FFF_FFFF
    }
}
