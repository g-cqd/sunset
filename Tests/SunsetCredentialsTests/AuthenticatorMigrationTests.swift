import Foundation
import Testing

@testable import SunsetCredentials

/// Google Authenticator's export (`otpauth-migration://offline?data=…`, roadmap 0093 B): a base64 protobuf
/// `MigrationPayload` of `OtpParameters` (secret 1, name 2, issuer 3, algorithm 4, digits 5, type 6, counter 7) and its
/// batch (version 2, size 3, index 4, id 5). Written here by hand, field by field, as the app writes it.
@Suite("Google Authenticator's export")
struct AuthenticatorMigrationTests {
    /// A varint.
    private func varint(_ value: UInt64) -> [UInt8] {
        var value = value
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(value & 0x7F)
            value >>= 7
            if value != 0 { byte |= 0x80 }
            bytes.append(byte)
        } while value != 0
        return bytes
    }

    private func field(_ number: UInt64, bytes: [UInt8]) -> [UInt8] {
        varint(number << 3 | 2) + varint(UInt64(bytes.count)) + bytes
    }

    private func field(_ number: UInt64, value: UInt64) -> [UInt8] {
        varint(number << 3) + varint(value)
    }

    private func otp(
        _ secret: String,
        _ name: String,
        _ issuer: String,
        algorithm: UInt64,
        digits: UInt64,
        type: UInt64,
        counter: UInt64 = 0
    ) -> [UInt8] {
        field(1, bytes: Array(secret.utf8)) + field(2, bytes: Array(name.utf8)) + field(3, bytes: Array(issuer.utf8))
            + field(4, value: algorithm) + field(5, value: digits) + field(6, value: type)
            + (counter > 0 ? field(7, value: counter) : [])
    }

    private func link(_ payload: [UInt8]) -> String {
        let data = Data(payload).base64EncodedString()
        let escaped = data.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? data
        return "otpauth-migration://offline?data=\(escaped)"
    }

    @Test func `two codes of a batch, each with its secret, names, algorithm, digits and kind`() throws {
        let payload =
            field(
                1,
                bytes: otp("12345678901234567890", "alice@example.com", "Example", algorithm: 1, digits: 1, type: 2)
            )
            + field(1, bytes: otp("abcdefghij", "ACME:bob", "", algorithm: 2, digits: 2, type: 1, counter: 7))
            + field(2, value: 1) + field(3, value: 2) + field(4, value: 0) + field(5, value: 99)
        let batch = try AuthenticatorMigration(link(payload))
        #expect(batch.size == 2 && batch.index == 0)
        #expect(batch.codes.count == 2)
        let first = batch.codes[0]
        #expect(first.kind == .totp && first.secret == Data("12345678901234567890".utf8))
        #expect(first.issuer == "Example" && first.account == "alice@example.com")
        #expect(first.algorithm == .sha1 && first.digits == 6 && first.period == 30)
        let second = batch.codes[1]
        #expect(second.kind == .hotp && second.counter == 7 && second.digits == 8 && second.algorithm == .sha256)
        #expect(second.issuer == "ACME" && second.account == "bob", "an issuer in the name when the field is empty")
    }

    @Test func `not a migration link, bad base64, a cut payload, or a code without a secret: refused`() throws {
        let good = otp("12345678901234567890", "a", "b", algorithm: 1, digits: 1, type: 2)
        for text in [
            "otpauth://totp/x?secret=JBSWY3DPEHPK3PXP", "otpauth-migration://offline?data=%%%",
            link(Array(field(1, bytes: good).dropLast(3))), link(field(1, bytes: field(2, bytes: Array("a".utf8))))
        ] {
            #expect(throws: AuthenticatorMigration.Invalid.self, "\(text.prefix(40))") {
                try AuthenticatorMigration(text)
            }
        }
    }
}
