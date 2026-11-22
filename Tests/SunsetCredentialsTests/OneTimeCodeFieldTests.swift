import Foundation
import Testing

@testable import SunsetCredentials

/// An entry's One-Time Code field (roadmap 0093 E): its value an `otpauth://` link or a bare base32 secret (as sites show
/// it, spaced or not); read, the code now, the seconds before it changes, and the next one.
@Suite("A One-Time Code field")
struct OneTimeCodeFieldTests {
    private let at = Date(timeIntervalSince1970: 59)

    @Test func `a link and a bare secret give the same code at the same time`() throws {
        // RFC 6238's SHA-1 key, base32.
        let secret = Base32.encode(Data("12345678901234567890".utf8)).replacing("=", with: "")
        let fromLink = try #require(OneTimeCodeField("otpauth://totp/x?secret=\(secret)&digits=8"))
        #expect(fromLink.code(at: at) == "94287082" && fromLink.secondsLeft(at: at) == 1)
        let bare = try #require(OneTimeCodeField(secret.lowercased().chunked(4)))
        #expect(bare.code(at: at) == "287082", "a bare secret: six digits, thirty seconds")
        #expect(bare.next(at: at) == bare.code(at: at.addingTimeInterval(30)))
    }

    @Test func `HOTP shows its counter's code; Steam its five characters; nonsense nothing`() throws {
        let secret = Base32.encode(Data("12345678901234567890".utf8)).replacing("=", with: "")
        let hotp = try #require(OneTimeCodeField("otpauth://hotp/x?secret=\(secret)&counter=1"))
        #expect(hotp.code(at: at) == "287082" && hotp.secondsLeft(at: at) == nil)
        let steam = try #require(OneTimeCodeField("otpauth://totp/Steam:x?secret=\(secret)&encoder=steam"))
        #expect(steam.code(at: at).count == 5)
        #expect(OneTimeCodeField("") == nil && OneTimeCodeField("not a secret!") == nil)
    }

    @Test func `shown in two halves, as authenticators do`() {
        #expect(OneTimeCodeField.spaced("123456") == "123 456" && OneTimeCodeField.spaced("12345678") == "1234 5678")
        #expect(OneTimeCodeField.spaced("ABCDE") == "ABCDE")
    }
}

extension String {
    fileprivate func chunked(_ size: Int) -> String {
        stride(from: 0, to: count, by: size).map { String(Array(self)[$0 ..< min($0 + size, count)]) }
            .joined(separator: " ")
    }
}
