import Foundation
package import SunsetDocuments
package import SunsetStorage

/// Everything Sunset keeps, opened once (R12, roadmap 0030): the places, the key that seals, and the database of small records.
/// What goes wrong is said (`StorageProblems`), never passed over: without the key nothing is saved in this run, and what is
/// sealed with another key is left as it is.
@MainActor
package final class SunsetStore {
    package let places: StoragePlaces
    /// Nil when the key cannot be had: the Keychain refused, or sealed things are here and their key is not.
    package let key: StorageKey?
    package let database: StateDatabase?
    /// The documents' index's database, once the documents are opened.
    private var library: StateDatabase?

    /// Whether a file of before goes to the Trash once kept (`storage.importedFiles`), read when one is retired.
    private let trashImported: @MainActor () -> Bool

    /// - Parameters:
    ///   - places: where everything is (`.current` for the app).
    ///   - problems: where what goes wrong is said.
    ///   - trashImported: the setting `storage.importedFiles` is `trash`.
    package init(places: StoragePlaces, problems: StorageProblems, trashImported: @escaping @MainActor () -> Bool) {
        self.places = places
        self.trashImported = trashImported
        let ring = StorageKeyring(vault: places.keyVault)
        var key: StorageKey?
        do {
            if let kept = try ring.existing() {
                key = kept
            } else if Self.holdsSealed(places) {
                // Sealed things without their key (another Mac's files, a Keychain not migrated): a new key would open none of
                // them, and saving would write over them. The recovery code brings the key back (Settings, Storage).
                problems.report(
                    StorageProblem(what: "What Sunset keeps", path: places.directory, movedTo: nil, kind: .locked)
                )
            } else {
                key = try ring.key()
            }
        } catch {
            problems.report(
                StorageProblem(what: "What Sunset keeps", path: places.directory, movedTo: nil, kind: .noKey)
            )
        }
        self.key = key
        guard let key else {
            database = nil
            return
        }
        let opened = StateDatabase.open(at: places.state, key: key)
        database = opened.database
        if let problem = opened.problem { problems.report(problem) }
    }

    /// The documents that live in Sunset (R12 step ST-4), opened at first use; nil when there is no key in this run. Their index
    /// is a database of its own (`library.sqlite`): it holds nothing the documents' files do not, and is rebuilt from them, so
    /// one that did not read is not said.
    /// The documents that are open, one per file or stored document for the whole app (roadmap 0023): every pane on one shows
    /// the same text.
    package private(set) lazy var openDocuments = OpenDocuments(store: documents)

    package private(set) lazy var documents: DocumentStore? = {
        guard let key else { return nil }
        let library = StateDatabase.open(at: places.library, key: key).database
        self.library = library
        let ours = places.isDefault
        return DocumentStore(folder: places.documents, library: library, key: key) { url in
            if ours {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            } else {
                try FileManager.default.removeItem(at: url)
            }
        }
    }()

    /// The files opened lately, listed with the documents (roadmap 0031): sealed in the state database, or in memory only
    /// when nothing can be kept in this run.
    package private(set) lazy var recentFiles = RecentFiles(table: table("recent-files"))

    /// The records of one kind; nil when nothing can be kept in this run (they are then in memory only).
    package func table(_ kind: String) -> SealedTable? {
        database?.table(kind)
    }

    package func seal(_ purpose: Seal.Purpose) -> Seal? {
        key.map { Seal(key: $0, purpose: purpose) }
    }

    /// Puts away a file of before the database once what it held is kept (`kept`: the store took it in, and the table holds
    /// what the store holds). A plain copy left in the folder would defeat the sealing. The person's own files go to the Mac's
    /// Trash, where nothing is destroyed, or are deleted, by `storage.importedFiles` (the owner, 2026-11-15: a setting, the
    /// Trash by default); a named setup's (a test's) are removed, so that tests do not fill the Trash.
    package func retire(_ legacy: String, when kept: Bool) {
        guard kept else { return }
        let trash = places.trashesImported(setting: trashImported())
        for suffix in ["", "-journal", "-wal", "-shm"] {
            let path = legacy + suffix
            guard FileManager.default.fileExists(atPath: path) else { continue }
            if trash {
                try? FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
            } else {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }

    /// Something sealed is in the folder: the database, or a sealed session.
    private static func holdsSealed(_ places: StoragePlaces) -> Bool {
        if FileManager.default.fileExists(atPath: places.state) { return true }
        guard let handle = FileHandle(forReadingAtPath: places.session) else { return false }
        defer { try? handle.close() }
        return Seal.isSealed((try? handle.read(upToCount: 4)) ?? Data())
    }

    /// Sunset quits: the databases are closed, their logs emptied (roadmap 0051 B).
    package func close() {
        database?.close()
        library?.close()
    }
}
