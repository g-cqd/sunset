package import Foundation
package import Observation
package import SunsetCredentials
package import SunsetRuntime

/// What the Library's Passwords section shows and does (roadmap 0091 E, ADR-0116): the person's vault, at `path`. No
/// vault: it is set up (a master password typed twice, Touch ID first when this Mac has it, the recovery code shown once).
/// Locked: it is unlocked. Unlocked: its entries, kept as they change. When the vault locks, for any reason, the model
/// lets go of every entry it held.
@MainActor @Observable
package final class PasswordsModel {
    package enum State: Equatable { case none, locked, unlocked }
    /// The two passwords typed differ, or are empty.
    package struct Mismatch: Error, Equatable {}

    package private(set) var state = State.none
    /// The entries, by title, while unlocked; none otherwise.
    package private(set) var entries: [VaultEntry] = []
    /// Whether Touch ID unlocks it.
    package private(set) var hasTouchID = false

    @ObservationIgnored private let path: String
    @ObservationIgnored private let cost: MasterPassword.Cost
    @ObservationIgnored private let runtime: Runtime
    @ObservationIgnored private let locks: VaultLocks
    @ObservationIgnored private var vault: Vault?

    package init(path: String, cost: MasterPassword.Cost = .standard, runtime: Runtime, locks: VaultLocks = .shared) {
        self.path = path
        self.cost = cost
        self.runtime = runtime
        self.locks = locks
        if FileManager.default.fileExists(atPath: path),
            let vault = try? Vault.open(at: path, runtime: runtime, locks: locks)
        {
            adopt(vault)
        }
    }

    /// Makes the vault: `password` and `again` must be the same, and not empty. With `touchID`, Touch ID is its first
    /// factor. The recovery code it returns is to be shown once; it is not kept.
    package func create(
        password: String,
        again: String,
        touchID: ((UUID) throws(TouchIDFactor.Refused) -> (TouchIDFactor, Data))? = nil
    ) throws -> RecoveryCode {
        guard !password.isEmpty, password == again else { throw Mismatch() }
        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let (made, code) = try Vault.create(
            at: path,
            password: password,
            touchID: touchID,
            cost: cost,
            runtime: runtime,
            locks: locks
        )
        adopt(made)
        return code
    }

    /// Unlocks with the master password; false when it is not this vault's.
    package func unlock(password: String) -> Bool {
        unlocking { try $0.unlock(password: password) }
    }

    /// Unlocks with Touch ID; false when it was refused or cancelled.
    package func unlockWithTouchID() -> Bool {
        unlocking { try $0.unlock(touchID: nil) }
    }

    package func lock() {
        vault?.lock.lock(.byHand)
    }

    /// A new entry made from `template`, kept.
    @discardableResult
    package func add(from template: EntryTemplate, title: String) throws -> VaultEntry {
        let entry = template.makeEntry(title: title)
        try save(entry)
        return entry
    }

    package func save(_ entry: VaultEntry) throws {
        guard let vault else { throw Vault.Refused() }
        try vault.save(entry)
        reload()
    }

    package func remove(_ id: UUID) throws {
        guard let vault else { throw Vault.Refused() }
        try vault.remove(entry: id)
        reload()
    }

    private func adopt(_ vault: Vault) {
        self.vault = vault
        hasTouchID = vault.factors.contains(.touchID)
        vault.lock.onLock = { [weak self] _ in self?.locked() }
        if vault.lock.isLocked { locked() } else { reload() }
    }

    private func unlocking(_ body: (Vault) throws -> Void) -> Bool {
        guard let vault, (try? body(vault)) != nil else { return false }
        reload()
        return true
    }

    private func locked() {
        state = .locked
        entries = []
    }

    private func reload() {
        guard let vault, !vault.lock.isLocked, let all = try? vault.entries() else { return locked() }
        state = .unlocked
        entries = all.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
