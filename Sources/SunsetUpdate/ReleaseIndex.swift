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
        case missingIndex
        case expired
        case metadataMismatch
    }

    /// Embedded Ed25519 public keys (32-byte raw representation, base64): main release key and offline backup key.
    public static let trustedPublicKeys: [Data] = [
        "6uFXHnlzNYE6Jtaj3vhIt56VOs3/ETi19e8dbRZ5glg=",
        "NZNAwNh/HdXVm7NOsyi1wqA6ZHK8DkXpghNMSrwkKHM="
    ]
    .compactMap { Data(base64Encoded: $0) }

    /// Default validity window for a signed release index (TUF timestamp/snapshot freshness, N-S1): 45 days.
    public static let defaultLifetime: TimeInterval = 45 * 86_400

    /// The first build for which Sunset requires a signed release index (v0.1.0-alpha.13, ADR-0125).
    public static let firstRequiredBuild = NotesCheck.firstSignedBuild

    public static let assetName = "release-index.json"
    public static let signatureAssetName = "release-index.json.sig"

    public let tag: String
    public let build: Int
    public let notesSHA256: String
    /// UNIX epoch seconds when the index was minted (optional on pre-N-S1 indexes).
    public let issuedAt: Int64?
    /// UNIX epoch seconds after which the index must be refused (freeze-attack protection, N-S1).
    public let expiresAt: Int64?
    public let variants: [Variant]

    public init(
        tag: String,
        build: Int,
        notesSHA256: String,
        issuedAt: Int64? = nil,
        expiresAt: Int64? = nil,
        variants: [Variant]
    ) {
        self.tag = tag
        self.build = build
        self.notesSHA256 = notesSHA256
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.variants = variants
    }

    /// Finds the entry for `flavour` and `architecture`.
    public func variant(for flavour: Flavour, architecture: String) -> Variant? {
        variants.first { $0.flavour == flavour && $0.architecture == architecture }
    }

    /// Verifies `signature` over `data` against any key in `trustedKeys`, decodes the index, and rejects an expired
    /// index when `now` is supplied (N-S1).
    public static func verify(
        data: Data,
        signature: Data,
        trustedKeys: [Data] = trustedPublicKeys,
        now: Date? = nil
    ) throws(Failure) -> Self {
        let valid = trustedKeys.contains { raw in
            guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw) else { return false }
            return key.isValidSignature(signature, for: data)
        }
        guard valid else { throw .untrustedSignature }
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { throw .malformed }
        if let now, let expiresAt = decoded.expiresAt {
            let nowSeconds = Int64(now.timeIntervalSince1970)
            guard nowSeconds <= expiresAt else { throw .expired }
            if let issuedAt = decoded.issuedAt, expiresAt < issuedAt { throw .malformed }
        }
        return decoded
    }

    /// Validates that `self` matches the GitHub release `tag` and `build`, and has not expired at `now`.
    public func validate(forTag expectedTag: String, build expectedBuild: Int, now: Date) throws(Failure) {
        guard tag == expectedTag, build == expectedBuild else { throw .metadataMismatch }
        if let expiresAt {
            let nowSeconds = Int64(now.timeIntervalSince1970)
            guard nowSeconds <= expiresAt else { throw .expired }
            if let issuedAt, expiresAt < issuedAt { throw .malformed }
        }
    }

    /// Whether a release at `build` must carry a signed release index.
    public static func isRequired(forBuild build: Int) -> Bool {
        build >= firstRequiredBuild
    }
}
