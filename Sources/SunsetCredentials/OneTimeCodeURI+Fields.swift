import Foundation

extension OneTimeCodeURI {
    /// A code made from its parts (an import's), not read from a URI: a period of 30 seconds.
    init(
        kind: Kind,
        issuer: String?,
        account: String,
        secret: Data,
        algorithm: OneTimeCode.Algorithm,
        digits: Int,
        counter: UInt64
    ) {
        self.kind = kind
        self.issuer = issuer
        self.account = account
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.counter = counter
    }
}
