public import Foundation

/// An `otpauth://` URI (roadmap 0093 B): Google's Key Uri Format, `otpauth://TYPE/ISSUER:ACCOUNT?secret=…&issuer=…`, with
/// its optional `algorithm`, `digits`, `period` and (HOTP) `counter`; Steam's as others write it (`encoder=steam`). What
/// would make a code no one can check (no secret, digits outside 6 to 10, a period of zero, an unknown algorithm, HOTP
/// without its counter) is refused.
public struct OneTimeCodeURI: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable { case totp, hotp, steam }
    public struct Invalid: Error, Equatable {}

    public var kind: Kind = .totp
    public var issuer: String?
    public var account = ""
    public var secret = Data()
    public var algorithm = OneTimeCode.Algorithm.sha1
    public var digits = 6
    public var period = 30
    public var counter: UInt64 = 0

    public init(_ text: String) throws(Invalid) {
        if let link = OTPLink.read(text, scheme: "steam"), let secret = try? Self.secret(link.host + link.path) {
            // steamguard's "steam://SECRET".
            kind = .steam
            self.secret = secret
            digits = 5
            return
        }
        guard let link = OTPLink.read(text, scheme: "otpauth") else { throw Invalid() }
        let query = link.query
        secret = try Self.secret(query["secret"] ?? "")
        // The type: none is TOTP; Steam however it is said.
        let (labelIssuer, account) = Self.split(String(link.path.drop { $0 == "/" }).trimmingCharacters(in: ["/"]))
        self.account = account
        issuer = query["issuer"].flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 } ?? labelIssuer
        kind = link.host == "hotp" ? .hotp : .totp
        let steam =
            link.host == "steam" || query["encoder"]?.lowercased() == "steam"
            || query["algorithm"]?.lowercased() == "steam"
            || (issuer?.lowercased() == "steam" && query["digits"] == "5")
        if steam {
            kind = .steam
            digits = 5
        } else {
            algorithm = try Self.algorithm(query["algorithm"])
            digits = try Self.number(query["digits"], or: 6)
        }
        period = try Self.number(query["period"], or: 30)
        counter = UInt64(try Self.number(query["counter"], or: 0))
        guard kind == .steam || OneTimeCode.Parameters(digits: digits, period: period).isValid, period > 0 else {
            throw Invalid()
        }
    }

    /// The URI written back, in Google's form.
    public var uri: String {
        var parts = URLComponents()
        parts.scheme = "otpauth"
        parts.host = kind == .steam ? "totp" : kind.rawValue
        parts.path = "/" + (issuer.map { "\($0):" } ?? "") + account
        var items = [URLQueryItem(name: "secret", value: Base32.encode(secret).replacing("=", with: ""))]
        if let issuer { items.append(URLQueryItem(name: "issuer", value: issuer)) }
        if kind == .steam {
            items.append(URLQueryItem(name: "encoder", value: "steam"))
        } else {
            items.append(URLQueryItem(name: "algorithm", value: algorithm.rawValue.uppercased()))
            items.append(URLQueryItem(name: "digits", value: String(digits)))
        }
        items.append(URLQueryItem(name: "period", value: String(period)))
        if kind == .hotp { items.append(URLQueryItem(name: "counter", value: String(counter))) }
        parts.queryItems = items
        return parts.string ?? ""
    }

    /// A label's issuer and account: "Issuer:account", or the account alone.
    private static func split(_ label: String) -> (String?, String) {
        guard let colon = label.firstIndex(of: ":") else { return (nil, label.trimmingCharacters(in: .whitespaces)) }
        let issuer = label[..<colon].trimmingCharacters(in: .whitespaces)
        return (issuer.isEmpty ? nil : issuer, label[label.index(after: colon)...].trimmingCharacters(in: .whitespaces))
    }

    /// A number however written: "08", " 8 ", "30s".
    private static func number(_ text: String?, or fallback: Int) throws(Invalid) -> Int {
        guard let text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return fallback }
        let digits = text.trimmingCharacters(in: .whitespaces).prefix { $0.isNumber }
        guard !digits.isEmpty, let value = Int(digits) else { throw Invalid() }
        return value
    }

    /// A secret in base32, spaced, dashed, padded or not, in any case; none, or one that does not read, is refused.
    private static func secret(_ text: String) throws(Invalid) -> Data {
        guard let secret = try? Base32.decode(text), !secret.isEmpty else { throw Invalid() }
        return secret
    }

    /// An algorithm as writers name it: "SHA1", "sha-256", "HmacSHA256", "HMAC-SHA512"; none is SHA-1.
    private static func algorithm(_ text: String?) throws(Invalid) -> OneTimeCode.Algorithm {
        let name = (text ?? "").lowercased().replacing("hmac", with: "").filter { $0.isLetter || $0.isNumber }
        if name.isEmpty { return .sha1 }
        guard let algorithm = OneTimeCode.Algorithm(rawValue: name) else { throw Invalid() }
        return algorithm
    }
}
