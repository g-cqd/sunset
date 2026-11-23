internal import CryptoKit
public import Foundation

/// Signed release index (`release-index.json` + `.sig`, ADR-0125): signed with Sunset's Ed25519 release key on the
/// signing Mac, verified against the embedded main and offline backup public keys before any untrusted archive, delta TOC,
/// or release notes are parsed or decompressed.
public struct ReleaseIndex: Equatable, Sendable, Codable {
    public struct Variant: Equatable, Sendable, Codable {
        public let flavour: Flavour
        public let architecture: String
        public let archiveName: String
        public let archiveSize: Int
        public let archiveSHA256: String
        public let deltasName: String?
        public let deltasSize: Int?
        public let deltasTOCSHA256: String?

        public init(
            flavour: Flavour,
            architecture: String,
            archiveName: String,
            archiveSize: Int,
            archiveSHA256: String,
            deltasName: String?,
            deltasSize: Int?,
            deltasTOCSHA256: String?
        ) {
            self.flavour = flavour
            self.architecture = architecture
            self.archiveName = archiveName
            self.archiveSize = archiveSize
            self.archiveSHA256 = archiveSHA256
            self.deltasName = deltasName
            self.deltasSize = deltasSize
            self.deltasTOCSHA256 = deltasTOCSHA256
        }
    }

    public enum Failure: Error, Equatable {
        case untrustedSignature
        case malformed
    }

    /// Embedded Ed25519 public keys (32-byte raw representation, base64): main release key and offline backup key.
    public static let trustedPublicKeys: [Data] = [
        "6uFXHnlzNYE6Jtaj3vhIt56VOs3/ETi19e8dbRZ5glg=",
        "NZNAwNh/HdXVm7NOsyi1wqA6ZHK8DkXpghNMSrwkKHM="
    ]
    .compactMap { Data(base64Encoded: $0) }

    public static let assetName = "release-index.json"
    public static let signatureAssetName = "release-index.json.sig"

    public let tag: String
    public let build: Int
    public let notesSHA256: String
    public let variants: [Variant]

    public init(tag: String, build: Int, notesSHA256: String, variants: [Variant]) {
        self.tag = tag
        self.build = build
        self.notesSHA256 = notesSHA256
        self.variants = variants
    }

    /// Finds the entry for `flavour` and `architecture`.
    public func variant(for flavour: Flavour, architecture: String) -> Variant? {
        variants.first { $0.flavour == flavour && $0.architecture == architecture }
    }

    /// Verifies `signature` over `data` against any key in `trustedKeys`, then decodes the index.
    public static func verify(
        data: Data,
        signature: Data,
        trustedKeys: [Data] = trustedPublicKeys
    ) throws(Failure) -> Self {
        let valid = trustedKeys.contains { raw in
            guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw) else { return false }
            return key.isValidSignature(signature, for: data)
        }
        guard valid else { throw .untrustedSignature }
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { throw .malformed }
        return decoded
    }
}
