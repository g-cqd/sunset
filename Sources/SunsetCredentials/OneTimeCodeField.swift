public import Foundation

/// An entry's One-Time Code field read (roadmap 0093 E): its value an `otpauth://` link, or a bare base32 secret as
/// sites show one (spaced, in any case: a TOTP of six digits every thirty seconds). The code now, the next one, and the
/// seconds before it changes (none for HOTP, whose code changes when it is used).
public struct OneTimeCodeField: Sendable, Equatable {
    public let link: OneTimeCodeURI

    /// Nil for a value that is neither a link nor a secret.
    public init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let link = try? OneTimeCodeURI(trimmed) {
            self.link = link
            return
        }
        guard !trimmed.isEmpty, let secret = try? Base32.decode(trimmed), secret.count >= 10,
            let link = try? OneTimeCodeURI("otpauth://totp/x?secret=\(Base32.encode(secret).replacing("=", with: ""))")
        else { return nil }
        self.link = link
    }

    public func code(at time: Date) -> String {
        code(counter: link.kind == .hotp ? link.counter : OneTimeCode.counter(at: time, period: link.period))
    }

    /// The code after this one.
    public func next(at time: Date) -> String {
        code(counter: (link.kind == .hotp ? link.counter : OneTimeCode.counter(at: time, period: link.period)) + 1)
    }

    /// The seconds before the code changes; nil for HOTP.
    public func secondsLeft(at time: Date) -> Int? {
        link.kind == .hotp ? nil : OneTimeCode.secondsLeft(at: time, period: link.period)
    }

    /// The code's period, for a countdown; nil for HOTP.
    public var period: Int? {
        link.kind == .hotp ? nil : link.period
    }

    /// A code of digits in two halves ("123 456", "1234 5678"), as authenticators show them; Steam's as it is.
    public static func spaced(_ code: String) -> String {
        guard code.count >= 6, code.allSatisfy(\.isNumber) else { return code }
        let half = code.index(code.startIndex, offsetBy: code.count / 2)
        return code[..<half] + " " + code[half...]
    }

    private func code(counter: UInt64) -> String {
        link.kind == .steam
            ? OneTimeCode.steam(secret: link.secret, counter: counter)
            : OneTimeCode.hotp(secret: link.secret, counter: counter, digits: link.digits, algorithm: link.algorithm)
    }
}
