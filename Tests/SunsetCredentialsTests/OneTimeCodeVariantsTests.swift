import Foundation
import Testing

@testable import SunsetCredentials

/// The links and secrets authenticators and sites write, read as permissively as can still give a code (the owner,
/// 2026-11-22): what can be computed is taken, whatever its spelling; only what cannot (no secret, an algorithm Sunset
/// cannot run, more digits than a code holds) is refused.
@Suite("One-time code links as they come")
struct OneTimeCodeVariantsTests {
    private let key = "JBSWY3DPEHPK3PXP"

    @Test(arguments: [
        "OTPAUTH://TOTP/Example:alice?SECRET=JBSWY3DPEHPK3PXP&ISSUER=Example",
        "  otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP  \n",
        "<otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP>",
        "\"otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP\"",
        "otpauth://totp/Example%3Aalice?secret=JBSWY3DPEHPK3PXP",
        "otpauth://totp/Example:%20alice?secret=jbsw%20y3dp%20ehpk%203pxp",
        "otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP%3D%3D%3D%3D",
        "otpauth://totp/Example:alice?secret=JBSW-Y3DP-EHPK-3PXP&issuer=",
        "otpauth:totp/Example:alice?secret=JBSWY3DPEHPK3PXP",
        "otpauth://totp/Example:alice/?secret=JBSWY3DPEHPK3PXP&image=https%3A%2F%2Fexample.com%2Fi.png&foo=bar"
    ])
    func `spellings of one link give its code`(link: String) throws {
        let code = try OneTimeCodeURI(link)
        #expect(code.secret == (try Base32.decode(key)) && code.kind == .totp)
        #expect(code.account == "alice" && code.issuer == "Example")
    }

    @Test(arguments: [
        ("SHA1", OneTimeCode.Algorithm.sha1), ("sha-256", .sha256), ("HmacSHA256", .sha256), ("HMAC-SHA512", .sha512),
        ("SHA512", .sha512), ("", .sha1)
    ])
    func `an algorithm however it is named`(name: String, algorithm: OneTimeCode.Algorithm) throws {
        #expect(try OneTimeCodeURI("otpauth://totp/x?secret=\(key)&algorithm=\(name)").algorithm == algorithm)
    }

    @Test func `numbers with units, padding or spaces; an HOTP without its counter starts at zero; no type is TOTP`()
        throws
    {
        let odd = try OneTimeCodeURI("otpauth://totp/x?secret=\(key)&digits=%2008%20&period=60s")
        #expect(odd.digits == 8 && odd.period == 60)
        #expect(try OneTimeCodeURI("otpauth://hotp/x?secret=\(key)").counter == 0)
        let untyped = try OneTimeCodeURI("otpauth:///alice?secret=\(key)")
        #expect(untyped.kind == .totp && untyped.account == "alice")
        #expect(try OneTimeCodeURI("otpauth://totp/?secret=\(key)").account.isEmpty)
    }

    @Test func `Steam however it is written`() throws {
        for link in [
            "steam://\(key)", "otpauth://totp/Steam:alice?secret=\(key)&issuer=Steam&digits=5",
            "otpauth://steam/alice?secret=\(key)", "otpauth://totp/Steam:alice?secret=\(key)&encoder=steam"
        ] {
            #expect(try OneTimeCodeURI(link).kind == .steam, "\(link)")
        }
    }

    @Test func `what cannot give a code is still refused`() {
        for link in [
            "otpauth://totp/x", "otpauth://totp/x?secret=", "otpauth://totp/x?secret=!!!",
            "otpauth://totp/x?secret=\(key)&algorithm=MD5", "otpauth://totp/x?secret=\(key)&digits=12",
            "otpauth://totp/x?secret=\(key)&period=0", "https://example.com/?secret=\(key)"
        ] {
            #expect(throws: OneTimeCodeURI.Invalid.self, "\(link)") { try OneTimeCodeURI(link) }
        }
    }
}
