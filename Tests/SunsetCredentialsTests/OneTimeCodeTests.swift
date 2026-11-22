import Foundation
import Testing

@testable import SunsetCredentials

/// One-time codes (roadmap 0093 A), against the published vectors: RFC 4226's appendix D (HOTP), RFC 6238's appendix B
/// (TOTP with SHA-1, SHA-256 and SHA-512, 8 digits), and Steam Guard's alphabet.
@Suite("One-time codes")
struct OneTimeCodeTests {
    private let sha1 = Data("12345678901234567890".utf8)
    private let sha256 = Data("12345678901234567890123456789012".utf8)
    private let sha512 = Data("1234567890123456789012345678901234567890123456789012345678901234".utf8)

    @Test func `HOTP: RFC 4226's ten values`() {
        let expected = [
            "755224", "287082", "359152", "969429", "338314", "254676", "287922", "162583", "399871", "520489"
        ]
        let codes = (0 ..< 10).map { OneTimeCode.hotp(secret: sha1, counter: UInt64($0), digits: 6, algorithm: .sha1) }
        #expect(codes == expected)
    }

    @Test(arguments: [
        (59.0, "94287082", "46119246", "90693936"),
        (1_111_111_109.0, "07081804", "68084774", "25091201"),
        (1_111_111_111.0, "14050471", "67062674", "99943326"),
        (1_234_567_890.0, "89005924", "91819424", "93441116"),
        (2_000_000_000.0, "69279037", "90698825", "38618901"),
        (20_000_000_000.0, "65353130", "77737706", "47863826")
    ])
    func `TOTP: RFC 6238's table`(time: Double, one: String, two: String, five: String) {
        let at = Date(timeIntervalSince1970: time)
        #expect(OneTimeCode.totp(secret: sha1, at: at, period: 30, digits: 8, algorithm: .sha1) == one)
        #expect(OneTimeCode.totp(secret: sha256, at: at, period: 30, digits: 8, algorithm: .sha256) == two)
        #expect(OneTimeCode.totp(secret: sha512, at: at, period: 30, digits: 8, algorithm: .sha512) == five)
    }

    @Test func `the time left in a code's period, and the next code`() {
        let at = Date(timeIntervalSince1970: 59)
        #expect(OneTimeCode.secondsLeft(at: at, period: 30) == 1)
        #expect(OneTimeCode.secondsLeft(at: Date(timeIntervalSince1970: 60), period: 30) == 30)
        let next = OneTimeCode.totp(
            secret: sha1,
            at: at.addingTimeInterval(30),
            period: 30,
            digits: 8,
            algorithm: .sha1
        )
        #expect(
            next
                == OneTimeCode.totp(
                    secret: sha1,
                    at: Date(timeIntervalSince1970: 60),
                    period: 30,
                    digits: 8,
                    algorithm: .sha1
                )
        )
    }

    @Test func `Steam: five characters of its alphabet, from the same truncation`() {
        // The value RFC 4226 truncates to at counter 0 is 1284755224; Steam takes it base 26 over its own alphabet.
        let code = OneTimeCode.steam(secret: sha1, counter: 0)
        #expect(code.count == 5)
        #expect(code.allSatisfy { "23456789BCDFGHJKMNPQRTVWXY".contains($0) })
        var value = 1_284_755_224
        let alphabet = Array("23456789BCDFGHJKMNPQRTVWXY")
        var expected = ""
        for _ in 0 ..< 5 {
            expected.append(alphabet[value % alphabet.count])
            value /= alphabet.count
        }
        #expect(code == expected)
    }

    @Test func `digits outside 6 to 10 are refused, a period of zero too`() {
        #expect(OneTimeCode.Parameters(digits: 5, period: 30).isValid == false)
        #expect(OneTimeCode.Parameters(digits: 11, period: 30).isValid == false)
        #expect(OneTimeCode.Parameters(digits: 6, period: 0).isValid == false)
        #expect(OneTimeCode.Parameters(digits: 10, period: 60).isValid)
    }
}
