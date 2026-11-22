import AppKit
import SunsetCredentials

/// Tells every open vault to lock (roadmap 0091 D): when the Mac goes to sleep or its displays do, when the screen
/// locks, when another user takes the Mac; and, from the app delegate, at quit and when the last window closes. Which
/// notification means what is decided, and tested, by `VaultLocks.reason(forNotificationNamed:)`.
@MainActor
enum AppVaultLocking {
    private static var observers: [(NotificationCenter, any NSObjectProtocol)] = []

    static func start() {
        guard observers.isEmpty else { return }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ] {
            observers.append((workspace, workspace.addObserver(forName: name, object: nil, queue: .main, using: heard)))
        }
        let distributed = DistributedNotificationCenter.default()
        let locked = Notification.Name("com.apple.screenIsLocked")
        observers.append(
            (distributed, distributed.addObserver(forName: locked, object: nil, queue: .main, using: heard))
        )
    }

    /// Every vault locks for `reason` (quit, last window closed).
    static func lockAll(_ reason: VaultLock.Reason) {
        VaultLocks.shared.lockAll(reason)
    }

    private nonisolated static func heard(_ note: Notification) {
        let name = note.name.rawValue
        MainActor.assumeIsolated {
            guard let reason = VaultLocks.reason(forNotificationNamed: name) else { return }
            VaultLocks.shared.lockAll(reason)
        }
    }
}
