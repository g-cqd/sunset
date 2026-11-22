/// Every open vault's lock (roadmap 0091 D): the app reports an event once, and every vault locks for it. The list
/// holds no vault alive: one let go of drops out.
@MainActor
public final class VaultLocks {
    public static let shared = VaultLocks()

    private struct Weak {
        weak var lock: VaultLock?
    }

    private var locks: [Weak] = []

    public init() {}

    /// How many vaults it holds now.
    public var count: Int {
        locks.count { $0.lock != nil }
    }

    public func add(_ lock: VaultLock) {
        locks.removeAll { $0.lock == nil }
        guard !locks.contains(where: { $0.lock === lock }) else { return }
        locks.append(Weak(lock: lock))
    }

    /// Locks every vault for `reason`.
    public func lockAll(_ reason: VaultLock.Reason) {
        locks.removeAll { $0.lock == nil }
        for entry in locks { entry.lock?.lock(reason) }
    }

    /// The reason to lock that a system notification is (by its name, as `NSWorkspace` and the distributed centre post
    /// it); nil for one that is not. Another user taking the Mac counts as the screen locked.
    public static func reason(forNotificationNamed name: String) -> VaultLock.Reason? {
        switch name {
            case "NSWorkspaceWillSleepNotification", "NSWorkspaceScreensDidSleepNotification": .sleep
            case "com.apple.screenIsLocked", "NSWorkspaceSessionDidResignActiveNotification": .screenLocked
            default: nil
        }
    }
}
