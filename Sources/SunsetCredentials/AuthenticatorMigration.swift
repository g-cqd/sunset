import Foundation

/// Google Authenticator's export (roadmap 0093 B): `otpauth-migration://offline?data=…`, a base64 protobuf
/// `MigrationPayload` of `OtpParameters` (secret 1, name 2, issuer 3, algorithm 4, digits 5, type 6, counter 7) and its
/// place in a batch of QR codes (size 3, index 4). An issuer left empty is read from the name ("ACME:bob"). A code
/// without a secret, or a payload that does not read whole, is refused.
public struct AuthenticatorMigration: Sendable, Equatable {
    public struct Invalid: Error, Equatable {}

    /// The codes, in the export's order.
    public var codes: [OneTimeCodeURI] = []
    /// How many QR codes the export was, and which this is.
    public var size = 1
    public var index = 0

    public init(_ text: String) throws(Invalid) {
        guard let link = OTPLink.read(text, scheme: "otpauth-migration"), let encoded = link.query["data"],
            let data = Data(base64Encoded: Self.padded(encoded))
        else { throw Invalid() }
        var reader = ProtobufReader(Array(data))
        guard let fields = try? reader.fields() else { throw Invalid() }
        for (number, value) in fields {
            switch (number, value) {
                case (1, .bytes(let bytes)): codes.append(try Self.code(bytes))
                case (3, .varint(let count)): size = Int(count)
                case (4, .varint(let place)): index = Int(place)
                default: continue
            }
        }
        guard !codes.isEmpty else { throw Invalid() }
    }

    /// One `OtpParameters`.
    private static func code(_ bytes: [UInt8]) throws(Invalid) -> OneTimeCodeURI {
        var reader = ProtobufReader(bytes)
        guard let fields = try? reader.fields() else { throw Invalid() }
        var (secret, name, issuer) = (Data(), "", "")
        var (algorithm, digits, type, counter) = (UInt64(1), UInt64(1), UInt64(2), UInt64(0))
        for (number, value) in fields {
            switch (number, value) {
                case (1, .bytes(let bytes)): secret = Data(bytes)
                case (2, .bytes(let bytes)): name = String(decoding: bytes, as: UTF8.self)
                case (3, .bytes(let bytes)): issuer = String(decoding: bytes, as: UTF8.self)
                case (4, .varint(let value)): algorithm = value
                case (5, .varint(let value)): digits = value
                case (6, .varint(let value)): type = value
                case (7, .varint(let value)): counter = value
                default: continue
            }
        }
        guard !secret.isEmpty else { throw Invalid() }
        let split = name.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let fromName = issuer.isEmpty && split.count == 2
        return OneTimeCodeURI(
            kind: type == 1 ? .hotp : .totp,
            issuer: fromName ? split[0] : (issuer.isEmpty ? nil : issuer),
            account: fromName ? split[1] : name,
            secret: secret,
            algorithm: [2: .sha256, 3: .sha512][algorithm] ?? .sha1,
            digits: digits == 2 ? 8 : 6,
            counter: counter
        )
    }

    /// Base64 as the link carries it: its padding may be gone.
    private static func padded(_ text: String) -> String {
        text + String(repeating: "=", count: (4 - text.count % 4) % 4)
    }
}
