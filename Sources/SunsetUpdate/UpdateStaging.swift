public import Foundation

/// A package applied to the running bundle in a staging folder (roadmap 0122 D): the running bundle is only read; the
/// staging copy is kept only when it is exactly the package's manifest (every file's SHA-256, every link, nothing more).
/// Its signature is checked after, by `SignatureCheck`.
public enum UpdateStaging {
    public enum Failure: Error, Equatable {
        /// The staged bundle is not the manifest (a delta made something else, a file is missing or extra).
        case notTheManifest
        /// A file the package copies or patches is not in the running bundle.
        case missing(String)
    }

    /// Builds `staging` (which must not exist) from `running` and `package`.
    public static func build(_ package: UpdatePackage, running: URL, staging: URL) throws {
        let files = FileManager.default
        try files.createDirectory(at: staging, withIntermediateDirectories: false)
        for item in package.items {
            let target = staging.appending(path: item.entry.path)
            try files.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            switch item.entry.kind {
                case .directory:
                    try files.createDirectory(at: target, withIntermediateDirectories: true)
                case .link:
                    try files.createSymbolicLink(atPath: target.path, withDestinationPath: item.entry.target ?? "")
                case .file:
                    try write(item, of: package, running: running, to: target)
            }
        }
        guard try BundleManifest.read(bundle: staging) == package.manifest else { throw Failure.notTheManifest }
    }

    /// One file: copied, or patched from its base.
    private static func write(_ item: UpdatePackage.Item, of package: UpdatePackage, running: URL, to target: URL)
        throws
    {
        if let copy = item.copy {
            let source = running.appending(path: copy)
            guard FileManager.default.fileExists(atPath: source.path) else { throw Failure.missing(copy) }
            try FileManager.default.copyItem(at: source, to: target)
        } else {
            let base = try item.base.map { path in
                let source = running.appending(path: path)
                guard FileManager.default.fileExists(atPath: source.path) else { throw Failure.missing(path) }
                return try Data(contentsOf: source)
            }
            try BinaryDelta.apply(package.delta(of: item) ?? Data(), to: base ?? Data()).write(to: target)
        }
        let mode = item.entry.executable == true ? 0o755 : 0o644
        try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: target.path)
    }
}
