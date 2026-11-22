import Foundation
public import SunsetRuntime
public import SunsetStorage

/// A vault's lock: unlocked, the vault key is held in a `SecretBuffer`; locked, it is zeroed and gone, and nothing of the
/// vault opens until a factor gives it again. It locks after `idle` without use (measured on the Runtime's monotonic
/// clock, so that a test moves the time), and at once for the other reasons, which the app reports.
@MainActor
public final class VaultLock {
    public enum Reason: Equatable, Sendable { case idle, quit, sleep, screenLocked, lastWindowClosed, byHand }

    /// Why it last locked; nil before it ever was unlocked.
    public private(set) var lockedBecause: Reason?
    private let idle: Duration
    private let runtime: Runtime
    private var key: SecretBuffer?
    private var lastUse = Duration.zero
    private var watch: Task<Void, Never>?

    public init(idle: Duration, runtime: Runtime) {
        self.idle = idle
        self.runtime = runtime
    }

    public var isLocked: Bool {
        key == nil
    }

    /// Holds `key` until it locks, and watches for idleness.
    public func unlock(with key: StorageKey) {
        self.key?.wipe()
        self.key = SecretBuffer(key.bytes)
        lockedBecause = nil
        lastUse = runtime.uptime()
        watch?.cancel()
        watch = runtime.task(role: .observation) { [weak self] in await self?.watchIdle() }
    }

    /// `body` with the vault key, which counts as a use; nil while locked.
    public func withKey<R>(_ body: (StorageKey) throws -> R) rethrows -> R? {
        guard let key else { return nil }
        lastUse = runtime.uptime()
        return try key.withBytes { try body(StorageKey(bytes: Data($0))) }
    }

    /// Zeroes and drops the key.
    public func lock(_ reason: Reason) {
        watch?.cancel()
        watch = nil
        guard let key else { return }
        key.wipe()
        self.key = nil
        lockedBecause = reason
    }

    /// Sleeps until the idle time would be over; locks if nothing used the key meanwhile, else sleeps again.
    private func watchIdle() async {
        while key != nil {
            guard await runtime.sleep(until: lastUse + idle) else { return }
            if key != nil, runtime.uptime() - lastUse >= idle {
                key?.wipe()
                key = nil
                lockedBecause = .idle
            }
        }
    }
}
