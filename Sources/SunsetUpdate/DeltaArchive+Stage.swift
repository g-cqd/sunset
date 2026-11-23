internal import Darwin
public import Foundation

extension DeltaArchive {
    /// Checks every `copyFrom` and `basePath` file in `running` matches its expected SHA-256 (never following symlinks),
    /// before downloading any payload bytes (ADR-0125). Returns `false` if the running bundle differs.
    public static func preflight(plan: SourcePlan, running: URL) throws -> Bool {
        for item in plan.items {
            if let copy = item.copyFrom, let want = item.baseSHA256 {
                guard let data = readRegularNoFollow(running.appending(path: copy)),
                    BundleManifest.hex(data) == want
                else { return false }
            } else if let base = item.basePath, let want = item.baseSHA256 {
                guard let data = readRegularNoFollow(running.appending(path: base)),
                    BundleManifest.hex(data) == want
                else { return false }
            }
        }
        return true
    }

    /// Rebuilds `staging` from `running`, `toc`, `plan`, and the downloaded contiguous `payload` slice. Verifies slice
    /// SHA-256, per-blob SHA-256, bounded decompression, per-file size caps, and final `BundleManifest` equality.
    public static func stage(
        toc: TOC,
        plan: SourcePlan,
        payload: Data,
        running: URL,
        staging: URL
    ) throws {
        guard payload.count == plan.rangeLength, BundleManifest.hex(payload) == plan.rangeSHA256 else {
            throw Failure.hashMismatch
        }
        let files = FileManager.default
        try files.createDirectory(at: staging, withIntermediateDirectories: false)
        let byPath = Dictionary(uniqueKeysWithValues: plan.items.map { ($0.path, $0) })
        var totalWritten = 0

        for entry in toc.targetManifest {
            let target = staging.appending(path: entry.path)
            try files.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            switch entry.kind {
                case .directory:
                    try files.createDirectory(at: target, withIntermediateDirectories: true)
                case .link:
                    guard entry.hasSafeTarget, let destination = entry.target else {
                        throw Failure.unsafeLink(entry.path)
                    }
                    try files.createSymbolicLink(atPath: target.path, withDestinationPath: destination)
                case .file:
                    guard let item = byPath[entry.path] else { throw Failure.malformed }
                    let written = try writeFile(
                        entry: entry,
                        item: item,
                        payload: payload,
                        running: running,
                        to: target
                    )
                    totalWritten += written
                    guard totalWritten <= maxTotalBytes else { throw Failure.sizeLimitExceeded }
            }
        }
        let expected = BundleManifest(entries: toc.targetManifest)
        guard try BundleManifest.read(bundle: staging) == expected else { throw Failure.hashMismatch }
    }

    private static func writeFile(
        entry: BundleEntry,
        item: Item,
        payload: Data,
        running: URL,
        to target: URL
    ) throws -> Int {
        let output: Data
        if let copy = item.copyFrom {
            guard let data = readRegularNoFollow(running.appending(path: copy)),
                data.count <= maxFileBytes
            else { throw Failure.missingSource(copy) }
            output = data
        } else {
            output = try applyBlob(item: item, payload: payload, running: running)
        }
        if let wantHash = entry.sha256, BundleManifest.hex(output) != wantHash { throw Failure.hashMismatch }
        try output.write(to: target, options: .atomic)
        let mode = entry.executable == true ? 0o755 : 0o644
        try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: target.path)
        return output.count
    }

    private static func applyBlob(item: Item, payload: Data, running: URL) throws -> Data {
        guard let kind = item.kind, let offset = item.offsetInRange, let length = item.length,
            let wantBlobHash = item.blobSHA256, let maxOut = item.expectedUncompressedSize,
            offset >= 0, length >= 0, length <= payload.count - offset, maxOut <= maxFileBytes
        else { throw Failure.malformed }
        let start = payload.startIndex + offset
        let blob = payload.subdata(in: start ..< (start + length))
        guard BundleManifest.hex(blob) == wantBlobHash else { throw Failure.hashMismatch }
        switch kind {
            case .full:
                return try BoundedLZMA.decompress(blob, maxOutput: maxOut)
            case .delta:
                guard let basePath = item.basePath,
                    let base = readRegularNoFollow(running.appending(path: basePath))
                else { throw Failure.missingSource(item.basePath ?? item.path) }
                return try BinaryDelta.apply(blob, to: base)
        }
    }

    /// Opens a file with `O_NOFOLLOW` and checks it is a regular file (never reads through symlinks in `running`).
    private static func readRegularNoFollow(_ url: URL) -> Data? {
        let fd = url.withUnsafeFileSystemRepresentation { path -> Int32 in
            guard let path = unsafe path else { return -1 }
            return unsafe open(path, O_RDONLY | O_NOFOLLOW)
        }
        guard fd >= 0 else { return nil }
        defer { close(fd) }
        var info = stat()
        guard unsafe fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG, info.st_size <= maxFileBytes else {
            return nil
        }
        return FileHandle(fileDescriptor: fd, closeOnDealloc: false).readDataToEndOfFile()
    }
}
