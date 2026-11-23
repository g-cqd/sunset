import CryptoKit
import Foundation
import Security
import Testing

@testable import SunsetWebModel

/// "Visit Anyway" trusts the certificate the person was shown, not any certificate for the host (the outside audit's
/// HIGH-04: a different certificate, one an attacker on the network presents, was trusted too).
@Suite("Certificate exceptions")
struct CertificateExceptionTests {
    /// A real certificate's trust: one of the system's roots.
    private func trust() throws -> (SecTrust, Data) {
        var anchors: CFArray?
        #expect(SecTrustCopyAnchorCertificates(&anchors) == errSecSuccess)
        let certificate = try #require((anchors as? [SecCertificate])?.first)
        var made: SecTrust?
        #expect(SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &made) == errSecSuccess)
        let digest = Data(SHA256.hash(data: SecCertificateCopyData(certificate) as Data))
        return (try #require(made), digest)
    }

    @Test func `a certificate failure keeps the fingerprint of the certificate shown`() throws {
        let (trust, digest) = try trust()
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSURLErrorFailingURLPeerTrustErrorKey: trust]
        )
        let failure = try #require(WebFailure(error, url: URL(string: "https://self-signed.example/")))
        #expect(failure.isCertificate && failure.certificate == digest)
        #expect(ServerCertificate.fingerprint(trust) == digest)
    }

    @Test func `an exception holds for its host and its certificate only`() {
        var exceptions = CertificateExceptions()
        let shown = Data(repeating: 1, count: 32)
        exceptions.accept(host: "Self-Signed.example", certificate: shown)
        #expect(exceptions.accepts(host: "self-signed.example", certificate: shown))
        #expect(!exceptions.accepts(host: "self-signed.example", certificate: Data(repeating: 2, count: 32)), "another")
        #expect(!exceptions.accepts(host: "other.example", certificate: shown))
        #expect(!exceptions.accepts(host: "self-signed.example", certificate: nil))
    }
}
