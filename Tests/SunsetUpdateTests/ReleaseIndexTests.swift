import CryptoKit
import Foundation
import SunsetUpdate
import Testing

/// Signed release index (ADR-0125): Ed25519 signature over the canonical index bytes, verified against embedded main or
/// backup public keys before any untrusted archive or delta TOC is parsed.
struct ReleaseIndexTests {
    @Test func acceptsMainOrBackupKeyAndRefusesTamperingOrUnknownKey() throws {
        let main = Curve25519.Signing.PrivateKey()
        let backup = Curve25519.Signing.PrivateKey()
        let rogue = Curve25519.Signing.PrivateKey()
        let keys = [main.publicKey.rawRepresentation, backup.publicKey.rawRepresentation]

        let index = ReleaseIndex(
            tag: "v0.1.0-alpha.13",
            build: 840,
            notesSHA256: String(repeating: "a", count: 64),
            variants: [
                ReleaseIndex.Variant(
                    flavour: .native,
                    architecture: "arm64",
                    archiveName: "Sunset-v0.1.0-alpha.13-build840-macos-arm64.zip",
                    archiveSize: 22_000_000,
                    archiveSHA256: String(repeating: "b", count: 64),
                    deltasName: "Sunset-v0.1.0-alpha.13-build840-macos-arm64.deltas",
                    deltasSize: 6_000_000,
                    deltasTOCSHA256: String(repeating: "c", count: 64)
                )
            ]
        )
        let bytes = try JSONEncoder().encode(index)

        for key in [main, backup] {
            let sig = try key.signature(for: bytes)
            let verified = try ReleaseIndex.verify(data: bytes, signature: sig, trustedKeys: keys)
            #expect(verified == index)
        }

        let rogueSig = try rogue.signature(for: bytes)
        #expect(throws: ReleaseIndex.Failure.untrustedSignature) {
            try ReleaseIndex.verify(data: bytes, signature: rogueSig, trustedKeys: keys)
        }

        let mainSig = try main.signature(for: bytes)
        var tampered = bytes
        tampered[0] ^= 0xFF
        #expect(throws: ReleaseIndex.Failure.untrustedSignature) {
            try ReleaseIndex.verify(data: tampered, signature: mainSig, trustedKeys: keys)
        }
    }

    @Test func embeddedKeysAreValid32ByteEd25519Keys() {
        #expect(ReleaseIndex.trustedPublicKeys.count == 2)
        for raw in ReleaseIndex.trustedPublicKeys {
            #expect(raw.count == 32)
            #expect((try? Curve25519.Signing.PublicKey(rawRepresentation: raw)) != nil)
        }
    }
}
