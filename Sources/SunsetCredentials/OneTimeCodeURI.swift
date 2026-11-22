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
        guard let parts = URLComponents(string: text), parts.scheme?.lowercased() == "otpauth",
            let type = parts.host?.lowercased(), var kind = Kind(rawValue: type), kind != .steam
        else { throw Invalid() }
        let query = Dictionary((parts.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }) { first, _ in
            first
        }
        guard let secretText = query["secret"], !secretText.isEmpty, let secret = try? Base32.decode(secretText),
            !secret.isEmpty
        else { throw Invalid() }
        let label = String(parts.path.dropFirst())
        let (labelIssuer, account) = Self.split(label)
        if query["encoder"]?.lowercased() == "steam" || query["algorithm"]?.lowercased() == "steam" { kind = .steam }
        self.kind = kind
        self.secret = secret
        self.account = account
        self.issuer = query["issuer"].flatMap { $0.isEmpty ? nil : $0 } ?? labelIssuer
        if let name = query["algorithm"], kind != .steam {
            guard let algorithm = OneTimeCode.Algorithm(rawValue: name.lowercased()) else { throw Invalid() }
            self.algorithm = algorithm
        }
        digits = kind == .steam ? 5 : try Self.number(query["digits"], or: 6)
        period = try Self.number(query["period"], or: 30)
        if kind == .hotp {
            guard let text = query["counter"], let counter = UInt64(text) else { throw Invalid() }
            self.counter = counter
        }
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

    private static func number(_ text: String?, or fallback: Int) throws(Invalid) -> Int {
        guard let text else { return fallback }
        guard let value = Int(text) else { throw Invalid() }
        return value
    }
}
