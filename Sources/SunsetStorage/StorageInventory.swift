import Foundation

/// What Settings say is kept (R12, roadmap 0030 step ST-6): each thing with its size, and the files that did not read and were
/// moved aside, listed from the folder (nothing remembers them). Reading it walks the folder: off the main thread.
public struct StorageInventory: Sendable, Equatable {
    /// A file that did not read and was moved aside under a dated name (`StoredFile.moveAside`).
    public struct SetAside: Sendable, Equatable, Identifiable {
        public let name: String
        public let path: String
        public let bytes: Int

        public var id: String { path }
    }

    /// The marker `StoredFile.moveAside` puts in a name, before the date.
    static let asideMarker = ".damaged-"

    public var documents = 0
    /// The documents' files and their index.
    public var documentBytes = 0
    public var sessionBytes = 0
    /// The database of small records, with its journal.
    public var stateBytes = 0
    /// The latest first.
    public var setAside: [SetAside] = []

    public init() {}

    public init(_ places: StoragePlaces) {
        let files = FileManager.default
        sessionBytes = Self.bytes(places.session)
        stateBytes = ["", "-wal", "-shm", "-journal"].reduce(0) { $0 + Self.bytes(places.state + $1) }
        documentBytes = ["", "-wal", "-shm", "-journal"].reduce(0) { $0 + Self.bytes(places.library + $1) }
        var aside: [SetAside] = []
        for folder in [places.directory, places.documents] {
            for name in (try? files.contentsOfDirectory(atPath: folder)) ?? [] where !name.hasPrefix(".") {
                let path = folder + "/" + name
                var isFolder: ObjCBool = false
                guard files.fileExists(atPath: path, isDirectory: &isFolder), !isFolder.boolValue else { continue }
                if name.contains(Self.asideMarker) {
                    aside.append(SetAside(name: name, path: path, bytes: Self.bytes(path)))
                } else if folder == places.documents, name.hasSuffix(".sealed") {
                    documents += 1
                    documentBytes += Self.bytes(path)
                }
            }
        }
        setAside = aside.sorted { Self.stamp($0.name) > Self.stamp($1.name) }
    }

    /// The date in the name of a file set aside, as text that sorts by time.
    private static func stamp(_ name: String) -> Substring {
        name.range(of: asideMarker).map { name[$0.upperBound...] } ?? ""
    }

    private static func bytes(_ path: String) -> Int {
        ((try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? NSNumber)?.intValue ?? 0
    }

    /// What the files at `paths` hold, folders counted through; a path that is not there counts for nothing.
    /// - Complexity: O(files).
    public static func size(of paths: [String]) -> Int {
        var total = 0
        for path in paths {
            var isFolder: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isFolder) else { continue }
            guard isFolder.boolValue else {
                total += bytes(path)
                continue
            }
            let walker = FileManager.default.enumerator(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
            )
            while let url = walker?.nextObject() as? URL {
                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if values?.isRegularFile == true { total += values?.fileSize ?? 0 }
            }
        }
        return total
    }

    /// Where WebKit keeps the website data of the app `bundle`: outside Sunset's folder, and not sealed.
    public static func websiteDataPaths(home: String, bundle: String) -> [String] {
        [
            home + "/Library/WebKit/" + bundle,
            home + "/Library/HTTPStorages/" + bundle,
            home + "/Library/HTTPStorages/" + bundle + ".binarycookies"
        ]
    }
}

extension StoragePlaces {
    /// Whether a plain file of before, once imported, goes to the Mac's Trash (`setting`: `storage.importedFiles` says the
    /// Trash) or is removed. A named setup's (a test's) are always removed, so that tests do not fill the Trash.
    public func trashesImported(setting: Bool) -> Bool { isDefault && setting }
}
