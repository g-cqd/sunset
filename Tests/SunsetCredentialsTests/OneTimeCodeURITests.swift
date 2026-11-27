import Foundation
import Testing

@testable import SunsetCredentials

/// `otpauth://` URIs (roadmap 0093 B), as Google's Key Uri Format writes them and as others vary it, and Base32 (RFC
/// 4648's vectors).
@Suite("otpauth URIs")
struct OneTimeCodeURITests {
    @Test func `Base32: RFC 4648's vectors, lowercase, spaces and missing padding accepted`() throws {
        let vectors = [
            ("", ""), ("f", "MY======"), ("fo", "MZXQ===="), ("foo", "MZXW6==="), ("foob", "MZXW6YQ="),
            ("fooba", "MZXW6YTB"), ("foobar", "MZXW6YTBOI======")
        ]
        for (plain, encoded) in vectors {
            #expect(try Base32.decode(encoded) == Data(plain.utf8))
            #expect(Base32.encode(Data(plain.utf8)) == encoded)
        }
        #expect(try Base32.decode("mzxw 6ytb oi") == Data("foobar".utf8))
        #expect(throws: Base32.Invalid.self) { try Base32.decode("MZXW1") }
    }

    @Test func `Google's example: issuer, account, secret; the defaults`() throws {
        let uri = "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
        let code = try OneTimeCodeURI(uri)
        #expect(code.kind == .totp && code.issuer == "Example" && code.account == "alice@google.com")
        #expect(code.secret == (try Base32.decode("JBSWY3DPEHPK3PXP")))
        #expect(code.algorithm == .sha1 && code.digits == 6 && code.period == 30)
    }

    @Test func `every parameter, percent-encoded labels, HOTP's counter`() throws {
        // The Key URI Format's own example key, not a credential.
        let example = "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
        let uri =
            "otpauth://hotp/ACME%20Co:john.doe%40email.com?secret=\(example)&issuer=ACME%20Co&algorithm=SHA256&digits=8&counter=7"
        let code = try OneTimeCodeURI(uri)
        #expect(code.kind == .hotp && code.issuer == "ACME Co" && code.account == "john.doe@email.com")
        #expect(code.algorithm == .sha256 && code.digits == 8 && code.counter == 7)
    }

    @Test func `the issuer from the label alone; Steam's own; what is refused`() throws {
        let fromLabel = try OneTimeCodeURI("otpauth://totp/GitHub:me?secret=JBSWY3DPEHPK3PXP")
        #expect(fromLabel.issuer == "GitHub" && fromLabel.account == "me")
        let steam = try OneTimeCodeURI("otpauth://totp/Steam:me?secret=JBSWY3DPEHPK3PXP&encoder=steam")
        #expect(steam.kind == .steam && steam.digits == 5)
        let bad = [
            "https://example.com", "otpauth://totp/x", "otpauth://totp/x?secret=not*base32",
            "otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&digits=12", "otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&period=0",
            "otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&algorithm=MD5"
        ]
        for uri in bad {
            #expect(throws: OneTimeCodeURI.Invalid.self, "\(uri)") { try OneTimeCodeURI(uri) }
        }
    }

    @Test func `written back as a URI that reads the same`() throws {
        let code = try OneTimeCodeURI(
            "otpauth://totp/ACME%20Co:jo%40x.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME%20Co&digits=8&period=60&algorithm=SHA512"
        )
        #expect(try OneTimeCodeURI(code.uri) == code)
    }
}
