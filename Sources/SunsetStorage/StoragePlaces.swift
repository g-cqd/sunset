import Foundation

/// Where each thing Sunset keeps is (R12, roadmap 0030 step ST-1): one folder, and the names in it. The only place that knows.
///
/// `$SUNSET_SESSION` names the session's file itself and puts everything else beside it; else `$SUNSET_CONFIG` (a test, a second
/// setup) puts everything beside that file, so that it never touches the person's own; else
/// `~/Library/Application Support/Sunset`. Empty variables count as unset.
public struct StoragePlaces: Sendable, Equatable {
    public let directory: String
    /// The open tabs, the folders and the Favorites: one file, read whole.
    public let session: String

    public init(environment: [String: String], home: String) {
        if let file = environment["SUNSET_SESSION"], !file.isEmpty {
            session = file
            directory = Self.folder(of: file)
            return
        }
        if let config = environment["SUNSET_CONFIG"], !config.isEmpty {
            directory = Self.folder(of: config)
        } else {
            var base = home
            while base.count > 1, base.hasSuffix("/") { base.removeLast() }
            directory = base + "/Library/Application Support/Sunset"
        }
        session = directory + "/session.json"
    }

    /// The places of this run.
    public static let current = StoragePlaces(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())

    /// The small records: page history, site zoom, site permissions, downloads (ST-3).
    public var state: String { directory + "/state.sqlite" }
    /// The documents, one file each (ST-4).
    public var documents: String { directory + "/Documents" }
    /// What the library shows of the documents; rebuilt from them (ST-4).
    public var library: String { directory + "/library.sqlite" }

    // The files of before the database, imported once by ST-3.
    public var legacyZoom: String { directory + "/site-zoom.json" }
    public var legacyHistory: String { directory + "/history.sqlite" }
    public var legacyDownloads: String { directory + "/downloads.json" }
    public var legacyPermissions: String { directory + "/site-permissions.json" }

    private static func folder(of path: String) -> String {
        path.lastIndex(of: "/").map { String(path[..<$0]) } ?? "."
    }
}
