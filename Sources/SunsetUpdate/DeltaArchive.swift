public import Foundation

/// Single range-addressed incremental update archive (`SSDLTA2`, ADR-0125): one `.deltas` file per flavour per release.
///
/// Layout:
/// - `[0 ..< 8]`   magic `"SSDLTA2\0"`
/// - `[8 ..< 16]`  `tocLength` (UInt64 LE, capped at `maxTOCLength`)
/// - `[16 ..< 48]` `tocSHA256` (32 bytes, SHA-256 of the compressed TOC bytes)
/// - `[48 ..< 48 + tocLength]` LZMA-compressed JSON `TOC` (bounded decode ≤ `maxTOCUncompressed`)
/// - `[48 + tocLength ..< EOF]` one contiguous payload slice per supported source build.
public enum DeltaArchive {
    public enum Failure: Error, Equatable {
        case notAnArchive
        case malformed
        case hashMismatch
        case duplicatePath(String)
        case outside(String)
        case unsafeLink(String)
        case missingSource(String)
        case sizeLimitExceeded
    }

    public struct Header: Equatable, Sendable {
        public static let magic = Data("SSDLTA2\0".utf8)
        public static let size = 8 + 8 + 32
        public static let maxTOCLength = 1 << 20
        public static let maxTOCUncompressed = 4 << 20

        public let tocLength: Int
        public let tocSHA256: String

        public init(tocLength: Int, tocSHA256: String) {
            self.tocLength = tocLength
            self.tocSHA256 = tocSHA256
        }

        public static func decode(_ data: Data) throws(Failure) -> Self {
            guard data.count >= magic.count, data.prefix(magic.count).elementsEqual(magic) else { throw .notAnArchive }
            guard data.count >= size else { throw .malformed }
            let bytes = [UInt8](data.prefix(size))
            guard let length = try? BinaryDelta.number(in: bytes, at: 8), length > 0, length <= maxTOCLength else {
                throw .malformed
            }
            let hex = bytes[16 ..< 48].map { String(format: "%02x", $0) }.joined()
            return Self(tocLength: length, tocSHA256: hex)
        }
    }

    public enum BlobKind: String, Equatable, Sendable, Codable {
        /// A `BinaryDelta` applied against `basePath`.
        case delta
        /// The full target file, LZMA-compressed (used for new files or when a delta is not smaller).
        case full
    }

    public struct Item: Equatable, Sendable, Codable {
        /// Target relative path (matches an entry in `TOC.targetManifest`).
        public let path: String
        /// Copied verbatim from this path in the running bundle (verified against `baseSHA256`).
        public let copyFrom: String?
        /// How to produce this file from the source's payload slice (`nil` when copied or non-file).
        public let kind: BlobKind?
        /// Path in the running bundle used as delta base (only for `.delta`).
        public let basePath: String?
        /// Expected SHA-256 of `copyFrom` or `basePath` in the running bundle (checked preflight).
        public let baseSHA256: String?
        /// Byte offset inside this source's contiguous payload slice.
        public let offsetInRange: Int?
        public let length: Int?
        public let blobSHA256: String?
        public let expectedUncompressedSize: Int?
    }

    public struct SourcePlan: Equatable, Sendable, Codable {
        /// Byte offset from the start of the payload region (`Header.size + tocLength`) for this source's single contiguous range.
        public let rangeOffset: Int
        public let rangeLength: Int
        public let rangeSHA256: String
        public let items: [Item]
    }

    public struct TOC: Equatable, Sendable, Codable {
        public let formatVersion: Int
        public let flavour: Flavour
        public let toBuild: Int
        public let targetManifest: [BundleEntry]
        public let sources: [String: SourcePlan]
    }

    public struct SourceInput: Sendable {
        public let key: String
        public let bundle: URL

        public init(key: String, bundle: URL) {
            self.key = key
            self.bundle = bundle
        }
    }

    public struct Built: Sendable {
        public let data: Data
        public let toc: TOC
        public let tocSHA256: String
    }

    /// Per-file uncompressed cap (256 MiB) and total staged bundle cap (1 GiB).
    public static let maxFileBytes = 256 << 20
    public static let maxTotalBytes = 1 << 30
    /// Default cap on previous source builds per flavour (`K = 3`).
    public static let defaultMaxSources = 3
    /// Default size cutoff: drop a source build if its delta exceeds 65% of the full zip.
    public static let defaultMaxRatio = 0.65

    /// Decodes and validates a compressed TOC slice against `expectedSHA256`.
    public static func decodeTOC(_ compressed: Data, expectedSHA256: String) throws(Failure) -> TOC {
        guard BundleManifest.hex(compressed) == expectedSHA256 else { throw .hashMismatch }
        let raw: Data
        do {
            raw = try BoundedLZMA.decompress(compressed, maxOutput: Header.maxTOCUncompressed)
        } catch {
            throw .malformed
        }
        guard let toc = try? JSONDecoder().decode(TOC.self, from: raw), toc.formatVersion == 2 else { throw .malformed }
        try validate(toc)
        return toc
    }

    /// Enforces manifest invariants: unique sorted paths, all paths inside bundle, all link targets safe, no writes
    /// under symlinks, all source item ranges within their slice.
    static func validate(_ toc: TOC) throws(Failure) {
        var seen = Set<String>()
        var links: [String] = []
        for entry in toc.targetManifest {
            guard entry.staysInside else { throw .outside(entry.path) }
            guard seen.insert(entry.path).inserted else { throw .duplicatePath(entry.path) }
            if entry.kind == .link {
                guard entry.hasSafeTarget else { throw .unsafeLink(entry.path) }
                links.append(entry.path + "/")
            }
        }
        for entry in toc.targetManifest where links.contains(where: entry.path.hasPrefix) {
            throw .outside(entry.path)
        }
        for plan in toc.sources.values {
            guard plan.rangeOffset >= 0, plan.rangeLength >= 0 else { throw .malformed }
            for item in plan.items {
                try validate(item: item, rangeLength: plan.rangeLength)
            }
        }
    }

    private static func validate(item: Item, rangeLength: Int) throws(Failure) {
        for path in [item.path, item.copyFrom, item.basePath].compactMap(\.self) {
            guard BundleEntry.directory(path).staysInside else { throw .outside(path) }
        }
        if let offset = item.offsetInRange {
            guard let length = item.length, offset >= 0, length >= 0, length <= rangeLength - offset,
                let uncompressed = item.expectedUncompressedSize, uncompressed >= 0, uncompressed <= maxFileBytes
            else { throw .malformed }
        }
    }
}
