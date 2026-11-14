import Foundation
import SunsetStorage

/// Everything Sunset keeps, opened once (R12, roadmap 0030): the places, the key that seals, and the database of small records.
/// What goes wrong is said (`StorageProblems`), never passed over: without the key nothing is saved in this run, and what is
/// sealed with another key is left as it is.
@MainActor
final class AppStorage {
    static let shared = AppStorage()

    let places: StoragePlaces
    /// Nil when the key cannot be had: the Keychain refused, or sealed things are here and their key is not.
    let key: StorageKey?
    let database: StateDatabase?

    init(places: StoragePlaces = .current, problems: StorageProblems = .shared) {
        self.places = places
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

    /// The records of one kind; nil when nothing can be kept in this run (they are then in memory only).
    func table(_ kind: String) -> SealedTable? { database?.table(kind) }

    func seal(_ purpose: Seal.Purpose) -> Seal? { key.map { Seal(key: $0, purpose: purpose) } }

    /// Puts away a file of before the database once what it held is kept (`kept`: the store took it in, and the table holds
    /// what the store holds). A plain copy left in the folder would defeat the sealing. The person's own files go to the Mac's
    /// Trash, where nothing is destroyed (the owner, 2026-11-14; to be reassessed: Trash or deleted); a named setup's (a test's)
    /// are removed, so that tests do not fill the Trash.
    func retire(_ legacy: String, when kept: Bool) {
        guard kept else { return }
        for suffix in ["", "-journal", "-wal", "-shm"] {
            let path = legacy + suffix
            guard FileManager.default.fileExists(atPath: path) else { continue }
            if places.isDefault {
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
}
