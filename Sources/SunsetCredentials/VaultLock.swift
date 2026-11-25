import Foundation
public import SunsetRuntime
public import SunsetStorage

/// A vault's lock: unlocked, the vault key is held in a `SecretBuffer`; locked, it is zeroed and gone, and nothing of the
/// vault opens until a factor gives it again. It locks after `idle` without use (measured on the Runtime's monotonic
/// clock, so that a test moves the time), and at once for the other reasons, which the app reports.
@MainActor
public final class VaultLock {
    public enum Reason: Equatable, Sendable {
        case idle, quit, sleep, screenLocked, lastWindowClosed, byHand
        /// Its page's tab was left, or its window stopped being the one in front, and the settings say to lock then.
        case leftTab, windowInactive
    }

    /// Why it last locked; nil before it ever was unlocked.
    public private(set) var lockedBecause: Reason?
    /// Told each time it locks, whatever the reason: what shows the vault lets go of what it held.
    public var onLock: (@MainActor (Reason) -> Void)?
    /// Told just before it locks, the key still there: what holds unkept edits keeps them (n138).
    public var willLock: (@MainActor (Reason) -> Void)?
    /// The time without use after which it locks; nil: never by itself (`passwords.lockAfter`). Changed while unlocked,
    /// it counts from the last use.
    public var idle: Duration? {
        didSet {
            guard key != nil else { return }
            watch?.cancel()
            watch = runtime.task(role: .observation) { [weak self] in await self?.watchIdle() }
        }
    }
    private let runtime: Runtime
    private var key: SecretBuffer?
    /// True when the raw key is held exclusively inside `SunsetVaultService.xpc` rather than in this process (N-S5).
    private var remoteUnlocked = false
    /// Invoked whenever the lock clears state (idle timeout or explicit `lock`) so an XPC vault wipes its key too.
    package var onWipeRemote: (@MainActor () -> Void)?
    private var lastUse = Duration.zero
    private var watch: Task<Void, Never>?

    public init(idle: Duration?, runtime: Runtime) {
        self.idle = idle
        self.runtime = runtime
    }

    public var isLocked: Bool {
        key == nil && !remoteUnlocked
    }

    /// Holds `key` in-process until it locks, and watches for idleness (used in bare SwiftPM tests / non-bundled CLI).
    public func unlock(with key: StorageKey) {
        self.key?.wipe()
        self.key = SecretBuffer(key.bytes)
        remoteUnlocked = false
        lockedBecause = nil
        lastUse = runtime.uptime()
        watch?.cancel()
        watch = runtime.task(role: .observation) { [weak self] in await self?.watchIdle() }
    }

    /// Marks the vault unlocked while the raw key lives exclusively inside `SunsetVaultService.xpc` (N-S5).
    package func unlockRemote() {
        self.key?.wipe()
        self.key = nil
        remoteUnlocked = true
        lockedBecause = nil
        lastUse = runtime.uptime()
        watch?.cancel()
        watch = runtime.task(role: .observation) { [weak self] in await self?.watchIdle() }
    }

    /// Records a remote XPC crypto operation as vault activity so the idle timer resets.
    package func touch() -> Bool {
        guard !isLocked else { return false }
        lastUse = runtime.uptime()
        return true
    }

    /// `body` with the in-process vault key, which counts as a use; nil while locked or when key lives in XPC.
    public func withKey<R>(_ body: (StorageKey) throws -> R) rethrows -> R? {
        guard let key else { return nil }
        lastUse = runtime.uptime()
        return try key.withBytes { try body(StorageKey(bytes: Data($0))) }
    }

    /// Zeroes and drops the key (locally and in XPC when remote).
    public func lock(_ reason: Reason) {
        watch?.cancel()
        watch = nil
        guard !isLocked else { return }
        willLock?(reason)
        guard !isLocked else { return }
        key?.wipe()
        key = nil
        if remoteUnlocked {
            remoteUnlocked = false
            onWipeRemote?()
        }
        lockedBecause = reason
        onLock?(reason)
    }

    /// Sleeps until the idle time would be over; locks if nothing used the key meanwhile, else sleeps again.
    private func watchIdle() async {
        while !isLocked, let idle {
            guard await runtime.sleep(until: lastUse + idle) else { return }
            if !isLocked, runtime.uptime() - lastUse >= idle {
                willLock?(.idle)
                key?.wipe()
                key = nil
                if remoteUnlocked {
                    remoteUnlocked = false
                    onWipeRemote?()
                }
                lockedBecause = .idle
                onLock?(.idle)
            }
        }
    }
}
