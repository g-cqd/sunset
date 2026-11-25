import Compression
public import Foundation

/// Disk store for per-pane terminal screen & scrollback snapshots (roadmap 0024 S-1, S-4 / t190, t215).
///
/// Snapshots are compressed with LZFSE before hitting disk, written atomically with `0700`/`0600` permissions, and
/// optionally authenticated/encrypted with `Seal(key:purpose: .terminalHistory)` bound to the pane's `UUID` (`S-4`).
/// Unreadable, tampered, or oversized snapshots are silently discarded rather than crashing launch.
public final class TerminalSnapshotStore: Sendable {
    /// Wire magic for compressed plain snapshots (`STSP` + version 1 + big-endian uncompressed byte count + LZFSE bytes).
    private static let plainMagic = Data("STSP".utf8)
    private static let formatVersion: UInt8 = 1
    /// Hard uncompressed cap on read (16 MiB) to defend against decompression bombs.
    public static let maximumUncompressedBytes = 16 << 20

    public let directory: URL
    private let seal: Seal?

    public init(directory: URL, key: StorageKey?) {
        self.directory = directory
        self.seal = key.map { Seal(key: $0, purpose: .terminalHistory) }
    }

    /// Saves `payload` (already JSON-encoded `ScreenSnapshot`) for `paneID`. When `encrypted` is true and a storage key
    /// is available, seals the compressed bytes with `Seal(.terminalHistory)` bound to `paneID`.
    public func save(_ payload: Data, for paneID: UUID, encrypted: Bool) {
        guard !payload.isEmpty, payload.count <= Self.maximumUncompressedBytes,
            let compressed = Self.compress(payload)
        else { return }
        let bytesToWrite: Data
        if encrypted, let seal {
            guard let sealed = try? seal.seal(compressed, identity: paneID.uuidString) else { return }
            bytesToWrite = sealed
        } else {
            bytesToWrite = compressed
        }
        let fm = FileManager.default
        try? fm.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let url = fileURL(for: paneID)
        try? bytesToWrite.write(to: url, options: .atomic)
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    /// Loads (and optionally removes) the saved snapshot bytes for `paneID`. Transparently opens either sealed or plain
    /// compressed snapshots so toggling `storage.encryptTerminalHistory` never strands existing snapshots.
    public func load(for paneID: UUID, removeAfterLoad: Bool = false) -> Data? {
        let url = fileURL(for: paneID)
        defer { if removeAfterLoad { try? FileManager.default.removeItem(at: url) } }
        guard let raw = try? Data(contentsOf: url), !raw.isEmpty else { return nil }
        let compressed: Data
        if Seal.isSealed(raw) {
            guard let seal, let opened = try? seal.open(raw, identity: paneID.uuidString) else { return nil }
            compressed = opened
        } else {
            compressed = raw
        }
        return Self.decompress(compressed)
    }

    /// Removes the saved snapshot for `paneID`.
    public func remove(for paneID: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: paneID))
    }

    /// Removes all saved snapshots whose pane IDs are not in `keeping` (prevents unbounded orphan buildup).
    public func prune(keeping: Set<UUID>) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: directory.path) else { return }
        for name in entries where name.hasSuffix(".snapshot") {
            let stem = String(name.dropLast(".snapshot".count))
            if let id = UUID(uuidString: stem), keeping.contains(id) { continue }
            try? fm.removeItem(at: directory.appending(path: name))
        }
    }

    /// Deletes every saved snapshot file on disk (used when the person declines restore or turns history restore off).
    public func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }

    public func fileURL(for paneID: UUID) -> URL {
        directory.appending(path: "\(paneID.uuidString).snapshot")
    }

    // MARK: - LZFSE framing

    private static func runLZFSE(_ input: Data, capacity: Int, encode: Bool) -> Data? {
        var out = Data(count: capacity)
        let written: Int = out.withUnsafeMutableBytes { dst in
            input.withUnsafeBytes { src in
                guard let dstBase = dst.bindMemory(to: UInt8.self).baseAddress,
                    let srcBase = src.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                if encode {
                    return unsafe compression_encode_buffer(
                        dstBase,
                        capacity,
                        srcBase,
                        input.count,
                        nil,
                        COMPRESSION_LZFSE
                    )
                }
                return unsafe compression_decode_buffer(dstBase, capacity, srcBase, input.count, nil, COMPRESSION_LZFSE)
            }
        }
        guard written > 0 else { return nil }
        out.removeSubrange(written ..< out.count)
        return out
    }

    private static func compress(_ input: Data) -> Data? {
        guard let body = runLZFSE(input, capacity: max(input.count + 64, 1024), encode: true) else { return nil }
        var header = Data()
        header.reserveCapacity(9 + body.count)
        header.append(plainMagic)
        header.append(formatVersion)
        let size = UInt32(input.count)
        for shift in stride(from: 24, through: 0, by: -8) {
            header.append(UInt8(truncatingIfNeeded: size >> shift))
        }
        header.append(body)
        return header
    }

    private static func decompress(_ input: Data) -> Data? {
        guard input.count > 9,
            input.prefix(plainMagic.count) == plainMagic,
            input[input.startIndex + 4] == formatVersion
        else { return nil }
        var expectedSize: UInt32 = 0
        for offset in 5 ..< 9 {
            expectedSize = (expectedSize << 8) | UInt32(input[input.startIndex + offset])
        }
        let targetCount = Int(expectedSize)
        guard targetCount > 0, targetCount <= maximumUncompressedBytes,
            let decoded = runLZFSE(Data(input.dropFirst(9)), capacity: targetCount, encode: false),
            decoded.count == targetCount
        else { return nil }
        return decoded
    }
}
