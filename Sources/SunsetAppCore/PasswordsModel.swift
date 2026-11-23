package import Foundation
import LocalAuthentication
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
    /// The password is shorter than `minimumLength` (ADR-0119).
    package struct TooShort: Error, Equatable {}
    package static let minimumLength = 12

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
    /// Edits a page noted and that are not kept yet, by entry (`noteEdit`, `keepPending`).
    @ObservationIgnored var pending: [UUID: VaultEntry] = [:]
    /// When it locks besides its idle time; neither until the settings say (`passwords.*`).
    @ObservationIgnored package var lockWhen = LockWhen(leavingTab: false, windowInactive: false)
    /// The idle time; the vault's own until the settings say (`lockAfter(minutes:)`).
    @ObservationIgnored var idle: Duration? = .seconds(600) {
        didSet {
            vault?.lock.idle = idle
        }
    }
    @ObservationIgnored private var throttle = UnlockThrottle()
    /// The recovery code of the vault just made, until the person says they kept it (t333: the window that showed it was
    /// seen closing by itself, and the code, shown once, was lost). In memory only.
    package private(set) var unkeptCode: RecoveryCode?

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

    /// Makes the vault: `password` and `again` must be the same, and at least `minimumLength` characters. With `touchID`, Touch ID is its first
    /// factor. The recovery code it returns is to be shown once; it is not kept.
    package func create(
        password: String,
        again: String,
        touchID: ((UUID) throws(TouchIDFactor.Refused) -> (TouchIDFactor, Data))? = nil
    ) throws -> RecoveryCode {
        guard !password.isEmpty, password == again else { throw Mismatch() }
        guard password.count >= Self.minimumLength else { throw TooShort() }
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
        unkeptCode = code
        return code
    }

    /// How long until a master password may be tried again after wrong ones (`UnlockThrottle`); nil when it may now.
    package var retryIn: Duration? {
        throttle.wait(at: runtime.uptime())
    }

    /// Unlocks with the master password; false when it is not this vault's, or when tries must wait (`retryIn`): then it
    /// is not tried at all.
    package func unlock(password: String) -> Bool {
        guard retryIn == nil else { return false }
        let opened = unlocking { try $0.unlock(password: password) }
        if opened { throttle.succeeded() } else { throttle.failed(at: runtime.uptime()) }
        return opened
    }

    /// Unlocks with Touch ID; false when it was refused or cancelled.
    package func unlockWithTouchID() -> Bool {
        let context = LAContext()
        context.localizedReason = "unlock your passwords"
        return unlocking { try $0.unlock(touchID: context) }
    }

    /// The person kept the recovery code: it is forgotten.
    package func codeKept() {
        unkeptCode = nil
    }

    package func lock(_ reason: VaultLock.Reason = .byHand) {
        vault?.lock.lock(reason)
    }

    /// A new entry made from `template`, kept.
    @discardableResult
    package func add(from template: EntryTemplate, title: String) throws -> VaultEntry {
        let entry = template.makeEntry(title: title)
        try save(entry)
        return entry
    }

    /// Keeps `entry`: its record alone is sealed and written; the list is changed in place, nothing else is opened again.
    package func save(_ entry: VaultEntry) throws {
        guard let vault else { throw Vault.Refused() }
        try vault.save(entry)
        pending[entry.id] = nil
        entries.removeAll { $0.id == entry.id }
        entries.insert(entry, at: entries.firstIndex { Self.before(entry, $0) } ?? entries.endIndex)
    }

    /// The sites never to offer saving for; none while locked. Read with the entries when unlocking.
    package private(set) var neverSave: Set<String> = []

    package func setNeverSave(_ site: String) throws {
        guard let vault else { throw Vault.Refused() }
        let sites = neverSave.union([site])
        try vault.setNeverSave(sites)
        neverSave = sites
    }

    package func remove(_ id: UUID) throws {
        guard let vault else { throw Vault.Refused() }
        try vault.remove(entry: id)
        entries.removeAll { $0.id == id }
    }

    private func adopt(_ vault: Vault) {
        self.vault = vault
        hasTouchID = vault.factors.contains(.touchID)
        vault.lock.onLock = { [weak self] _ in self?.locked() }
        vault.lock.willLock = { [weak self] _ in self?.keepPending() }
        vault.lock.idle = idle
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
        neverSave = []
    }

    /// Opens every record once (after unlocking): the entries by title, and the sites never to save for.
    private func reload() {
        guard let vault, !vault.lock.isLocked, let contents = try? vault.contents() else { return locked() }
        state = .unlocked
        entries = contents.entries.sorted(by: Self.before)
        neverSave = contents.neverSave
    }

    /// The list's order: by title, as the Finder sorts names.
    private static func before(_ first: VaultEntry, _ second: VaultEntry) -> Bool {
        first.title.localizedStandardCompare(second.title) == .orderedAscending
    }
}
