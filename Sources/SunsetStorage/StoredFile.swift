internal import AemiIO
public import Foundation
public import SunsetRuntime

/// A file Sunset keeps (R12, roadmap 0030 step ST-1): written whole or not at all, and never dropped silently when it does not
/// read.
public enum StoredFile {
    /// How hard a write is pushed to the disk before it counts as done.
    public enum Durability: Sendable {
        /// In order, without waiting for the drive's own cache: safe against a crash, for what is written often (the session).
        case ordered
        /// The drive's cache too: safe against a power loss, for what the person made (a document).
        case forced
    }

    /// Writes `data` at `path`, making its folder: a temporary file beside it, synced, renamed over it, the folder synced
    /// (Aemi's `AtomicFile`). A crash leaves the old file or the new one, never a mix or an empty file. Readable by its owner
    /// only, unless `permissions` says otherwise (a file that leaves Sunset's folder for the person's).
    public static func write(
        _ data: Data,
        to path: String,
        durability: Durability = .ordered,
        permissions: UInt16 = 0o600
    ) throws(StorageFailure) {
        let folder = (path as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        } catch {
            throw StorageFailure(step: "create \(folder)", code: Int32((error as NSError).code))
        }
        do {
            try AtomicFile.replace(
                at: path,
                with: Array(data),
                durability: durability == .forced ? .full : .barrier,
                permissions: permissions
            )
        } catch {
            throw StorageFailure(step: error.op, code: error.errno)
        }
    }

    /// Reads the file and gives it to `decode`. A file that is there and that `decode` does not accept is moved aside
    /// (`moveAside`) and comes back as `.damaged`, to be said; `what` names it for the person ("The saved session").
    public static func read<Value>(
        _ path: String,
        as what: String,
        now: Date = Runtime.live.now(),
        decode: (Data) -> Value?
    ) -> StoredRead<Value> {
        guard let data = FileManager.default.contents(atPath: path) else { return .absent }
        if let value = decode(data) { return .value(value) }
        return .damaged(StorageProblem(what: what, path: path, movedTo: moveAside(path, now: now)))
    }

    /// Renames the file to `name.damaged-<date>` beside itself (a number is added when that name is taken), and says the new
    /// path; nil when it could not be renamed. Nothing of the file is lost: the person, or a later version, can still read it.
    public static func moveAside(_ path: String, now: Date = Runtime.live.now()) -> String? {
        // The person's own date and time, as they would look for it.
        let stamp = now.formatted(
            Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash)
                .time(includingFractionalSeconds: false).timeSeparator(.omitted)
        )
        let base = path + ".damaged-" + stamp
        for attempt in 1 ... 100 {
            let candidate = attempt == 1 ? base : "\(base)-\(attempt)"
            guard !FileManager.default.fileExists(atPath: candidate) else { continue }
            do {
                try FileManager.default.moveItem(atPath: path, toPath: candidate)
                return candidate
            } catch {
                return nil
            }
        }
        return nil
    }
}
