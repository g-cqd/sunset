import CryptoKit
import Foundation
import Security
import Testing

@testable import SunsetWebModel

/// A Chrome extension's package is read only when its signature holds (the outside audit's CRIT-03: the header was taken off
/// unread, so a package altered anywhere installed). CRX3: the archive and the signed header data signed by every key the
/// header lists, one of them the key the extension's id is made from.
@Suite("CRX3 signatures")
struct CRX3SignatureTests {
    private static let zip = SignedCRX.zip

    @Test func `signed by its id's key, RSA or ECDSA: the archive is read`() throws {
        for signer in [try SignedCRX.rsa(), SignedCRX.ecdsa()] {
            #expect(try ExtensionPackage.zip(from: SignedCRX.package([signer], idKey: signer.spki)) == Self.zip)
        }
    }

    @Test func `an altered archive, a key not its id's, or no signature: refused`() throws {
        let signer = SignedCRX.ecdsa()
        let other = SignedCRX.ecdsa()
        #expect(throws: ExtensionPackage.Refused.self) {
            try ExtensionPackage.zip(from: SignedCRX.package([signer], idKey: signer.spki, tamper: true))
        }
        #expect(throws: ExtensionPackage.Refused.self) {
            try ExtensionPackage.zip(from: SignedCRX.package([other], idKey: signer.spki))
        }
        #expect(throws: ExtensionPackage.Refused.self) {
            try ExtensionPackage.zip(from: SignedCRX.package([], idKey: signer.spki))
        }
    }

    @Test func `every signature listed must hold, not only the id's`() throws {
        let signer = SignedCRX.ecdsa()
        let broken = SignedCRX.Signer(spki: SignedCRX.ecdsa().spki, field: 3) { _ in Data(repeating: 0x30, count: 8) }
        #expect(throws: ExtensionPackage.Refused.self) {
            try ExtensionPackage.zip(from: SignedCRX.package([signer, broken], idKey: signer.spki))
        }
    }
}
