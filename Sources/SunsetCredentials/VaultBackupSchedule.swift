public import Foundation
public import SunsetRuntime

/// Automatic `.svault` backups to a chosen folder (roadmap 0095 B): writes timestamped, owner-only (`0600`) sealed
/// snapshots and prunes only older Sunset vault backups beyond `keep`, never touching unrelated files.
public enum VaultBackupSchedule {
    public static let filePrefix = "Sunset-Vault-"

    /// Writes a new sealed `.svault` snapshot of `file` into `directory` (created if needed), then deletes the oldest
    /// Sunset vault backups beyond `max(keep, 1)`. Returns the written file's URL.
    @discardableResult
    public static func run(
        file: VaultFile,
        into directory: URL,
        keep: Int,
        now: Date = Runtime.live.now()
    ) throws(VaultBackup.Failure) -> URL {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw .writeFailed
        }
        let data = try VaultBackup.export(from: file, createdAt: now)
        let name = "\(filePrefix)\(stamp(now)).\(VaultBackup.fileExtension)"
        let destination = directory.appending(path: name)
        try VaultBackup.writeOwnerOnly(data, to: destination)
        prune(in: directory, keeping: max(keep, 1))
        return destination
    }

    /// Existing Sunset vault backups in `directory`, sorted oldest-first by filename.
    public static func list(in directory: URL) -> [URL] {
        guard
            let items = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else { return [] }
        let suffix = ".\(VaultBackup.fileExtension)"
        return
            items
            .filter { $0.lastPathComponent.hasPrefix(filePrefix) && $0.lastPathComponent.hasSuffix(suffix) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Removes the oldest Sunset vault backups past `keeping`.
    public static func prune(in directory: URL, keeping: Int) {
        let all = list(in: directory)
        let limit = max(keeping, 1)
        guard all.count > limit else { return }
        for old in all.prefix(all.count - limit) {
            try? FileManager.default.removeItem(at: old)
        }
    }

    private static func stamp(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            in: TimeZone(secondsFromGMT: 0) ?? .gmt,
            from: date
        )
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        return String(
            format: "%04d-%02d-%02d-%02d%02d%02dZ",
            year,
            month,
            day,
            hour,
            minute,
            second
        )
    }
}
