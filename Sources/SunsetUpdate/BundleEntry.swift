/// One item of an app bundle, as an update rebuilds it: a file (its SHA-256, size and whether it is executable), a
/// symbolic link (its target) or a directory. `path` is relative to the bundle (`Contents/MacOS/Sunset`).
public struct BundleEntry: Equatable, Sendable, Codable {
    public enum Kind: String, Sendable, Codable {
        case file
        case link
        case directory
    }

    public let path: String
    public let kind: Kind
    /// A file's SHA-256, lowercase hex.
    public let sha256: String?
    public let size: Int?
    public let executable: Bool?
    /// A link's target, as written.
    public let target: String?

    public static func file(_ path: String, sha256: String, size: Int, executable: Bool) -> Self {
        Self(path: path, kind: .file, sha256: sha256, size: size, executable: executable, target: nil)
    }

    public static func link(_ path: String, target: String) -> Self {
        Self(path: path, kind: .link, sha256: nil, size: nil, executable: nil, target: target)
    }

    public static func directory(_ path: String) -> Self {
        Self(path: path, kind: .directory, sha256: nil, size: nil, executable: nil, target: nil)
    }

    /// Whether `path` stays inside the bundle: relative, no `..`, no empty part (an update never writes elsewhere).
    public var staysInside: Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        return !path.hasPrefix("/") && !parts.isEmpty && !parts.contains { $0.isEmpty || $0 == ".." || $0 == "." }
    }

    /// For a symlink entry, whether `target` is non-empty, relative, and resolves inside the bundle root (ADR-0125).
    public var hasSafeTarget: Bool {
        guard kind == .link else { return true }
        guard let target, !target.isEmpty, !target.hasPrefix("/") else { return false }
        var depth = path.split(separator: "/").count - 1
        for component in target.split(separator: "/", omittingEmptySubsequences: false) {
            if component.isEmpty || component == "." { continue }
            if component == ".." {
                depth -= 1
                if depth < 0 { return false }
            } else {
                depth += 1
            }
        }
        return true
    }
}
