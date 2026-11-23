internal import CryptoKit
public import Foundation

/// Every item of an app bundle (roadmap 0122 C), sorted by path: what an update must rebuild exactly.
public struct BundleManifest: Equatable, Sendable, Codable {
    public let entries: [BundleEntry]

    public init(entries: [BundleEntry]) {
        self.entries = entries.sorted { $0.path < $1.path }
    }

    /// The bundle at `bundle` as it is on disk; links are recorded, not followed.
    public static func read(bundle: URL) throws -> Self {
        let root = bundle.standardizedFileURL.path
        guard let walker = FileManager.default.enumerator(atPath: root) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        var entries: [BundleEntry] = []
        while let relative = walker.nextObject() as? String {
            entries.append(try entry(relative, in: root))
        }
        return Self(entries: entries)
    }

    /// The item at `relative` under `root`.
    static func entry(_ relative: String, in root: String) throws -> BundleEntry {
        let path = root + "/" + relative
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        switch attributes[.type] as? FileAttributeType {
            case .typeSymbolicLink:
                return .link(relative, target: try FileManager.default.destinationOfSymbolicLink(atPath: path))
            case .typeDirectory:
                return .directory(relative)
            default:
                let data = try Data(contentsOf: URL(filePath: path), options: .mappedIfSafe)
                let mode = (attributes[.posixPermissions] as? Int) ?? 0
                return .file(relative, sha256: hex(data), size: data.count, executable: mode & 0o111 != 0)
        }
    }

    /// SHA-256 in lowercase hex.
    public static func hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// The files by their SHA-256 (the first path of each).
    public var filesByHash: [String: BundleEntry] {
        var byHash: [String: BundleEntry] = [:]
        for entry in entries where entry.kind == .file {
            if let hash = entry.sha256, byHash[hash] == nil { byHash[hash] = entry }
        }
        return byHash
    }
}
