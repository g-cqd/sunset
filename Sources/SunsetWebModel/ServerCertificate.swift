internal import CryptoKit
package import Foundation
package import Security

/// A server's certificate as Sunset remembers it: the SHA-256 of its leaf (the certificate the server presents for itself).
package enum ServerCertificate {
    /// The leaf's fingerprint; nil when the trust has no certificate.
    package static func fingerprint(_ trust: SecTrust) -> Data? {
        guard let leaf = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first else { return nil }
        return Data(SHA256.hash(data: SecCertificateCopyData(leaf) as Data))
    }

    /// The fingerprint of the trust an error carries (`NSURLErrorFailingURLPeerTrustErrorKey`); nil when it carries none.
    package static func fingerprint(of value: Any?) -> Data? {
        guard let value, CFGetTypeID(value as CFTypeRef) == SecTrustGetTypeID() else { return nil }
        return fingerprint(unsafeDowncast(value as AnyObject, to: SecTrust.self))
    }
}
