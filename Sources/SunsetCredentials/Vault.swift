public import Foundation
public import LocalAuthentication
public import SunsetRuntime
import SunsetStorage

/// A vault (roadmap 0091): its file, its factors and its lock. Made with a master password and a recovery code (shown
/// once, never kept); opened locked; any one factor unlocks it to the vault's key, which its lock holds until it locks.
@MainActor
public final class Vault {
    public enum Factor: String, Equatable, Sendable, Codable { case password, recoveryCode, touchID }
    /// The factor given does not unlock this vault (a wrong password, another vault's code, a changed slot).
    public struct Refused: Error, Equatable {}

    public let file: VaultFile
    public let lock: VaultLock
    private let locks: VaultLocks

    init(file: VaultFile, lock: VaultLock, locks: VaultLocks) {
        self.file = file
        self.lock = lock
        self.locks = locks
    }

    /// The factors that unlock it.
    public var factors: [Factor] {
        ((try? file.factorSlots()) ?? []).map(\.factor)
    }

    /// Makes a vault at `path`, unlocked: a new key, wrapped by Touch ID when `touchID` makes its factor (the app asks
    /// for the fingers enrolled; a test, no one), by `password` (stretched at `cost`), and by a new recovery code, which is
    /// returned to be shown once.
    public static func create(
        at path: String,
        password: String,
        touchID: ((UUID) throws(TouchIDFactor.Refused) -> (TouchIDFactor, Data))? = nil,
        cost: MasterPassword.Cost = .standard,
        idle: Duration = .seconds(600),
        runtime: Runtime,
        locks: VaultLocks = .shared
    ) throws -> (Vault, RecoveryCode) {
        let file = try VaultFile.create(at: path)
        let key = StorageKey.random()
        let salt = StorageKey.random().bytes.prefix(16)
        let stretched = try MasterPassword.stretch(password, salt: Data(salt), cost: cost)
        let code = RecoveryCode.generate()
        var slots: [VaultFile.FactorSlot] = []
        // Touch ID first, when asked for: the everyday factor; the password its fallback.
        if let touchID {
            let (factor, factorKey) = try touchID(file.id)
            slots.append(
                VaultFile.FactorSlot(
                    factor: .touchID,
                    wrapped: try WrappedKey.wrap(key, with: factorKey, factor: Factor.touchID.rawValue, vault: file.id),
                    touchID: factor.bytes
                )
            )
        }
        try file.setFactorSlots(
            slots + [
                VaultFile.FactorSlot(
                    factor: .password,
                    wrapped: try WrappedKey.wrap(
                        key,
                        with: stretched,
                        factor: Factor.password.rawValue,
                        vault: file.id
                    ),
                    salt: Data(salt),
                    cost: cost
                ),
                VaultFile.FactorSlot(
                    factor: .recoveryCode,
                    wrapped: try WrappedKey.wrap(
                        key,
                        with: code.factorKey(vault: file.id),
                        factor: Factor.recoveryCode.rawValue,
                        vault: file.id
                    )
                )
            ]
        )
        let vault = Vault(file: file, lock: VaultLock(idle: idle, runtime: runtime), locks: locks)
        vault.unlocked(key)
        return (vault, code)
    }

    /// Opens the vault at `path`, locked.
    public static func open(
        at path: String,
        idle: Duration = .seconds(600),
        runtime: Runtime,
        locks: VaultLocks = .shared
    ) throws -> Vault {
        Vault(file: try VaultFile.open(at: path), lock: VaultLock(idle: idle, runtime: runtime), locks: locks)
    }

    public func unlock(password: String) throws(Refused) {
        let slot = try slot(.password)
        guard let salt = slot.salt, let cost = slot.cost,
            let stretched = try? MasterPassword.stretch(password, salt: salt, cost: cost)
        else { throw Refused() }
        try unwrap(slot, with: stretched)
    }

    /// Unlocks with Touch ID, asked through `context` (nil: the system's own prompt).
    public func unlock(touchID context: LAContext?) throws(Refused) {
        let slot = try slot(.touchID)
        guard let bytes = slot.touchID, let factor = try? TouchIDFactor(bytes),
            let factorKey = try? factor.factorKey(vault: file.id, context: context)
        else { throw Refused() }
        try unwrap(slot, with: factorKey)
    }

    public func unlock(recoveryCode: RecoveryCode) throws(Refused) {
        try unwrap(slot(.recoveryCode), with: recoveryCode.factorKey(vault: file.id))
    }

    private func unwrap(_ slot: VaultFile.FactorSlot, with factorKey: Data) throws(Refused) {
        guard let key = try? slot.wrapped.unwrap(with: factorKey, vault: file.id) else { throw Refused() }
        unlocked(key)
    }

    /// Writes `record` sealed under `id`. Refused while locked.
    public func put(_ record: Data, as id: UUID) throws {
        guard let done = try lock.withKey({ key in try file.put(record, as: id, key: key) }) else { throw Refused() }
        done
    }

    /// The record `id`, opened; nil when there is none. Refused while locked.
    public func record(_ id: UUID) throws -> Data? {
        guard let record = try lock.withKey({ key in try file.record(id, key: key) }) else { throw Refused() }
        return record
    }

    private func slot(_ factor: Factor) throws(Refused) -> VaultFile.FactorSlot {
        guard let slot = (try? file.factorSlots())?.first(where: { $0.factor == factor }) else { throw Refused() }
        return slot
    }

    /// Holds `key`, and joins the vaults that lock at once.
    private func unlocked(_ key: StorageKey) {
        lock.unlock(with: key)
        locks.add(lock)
    }
}
