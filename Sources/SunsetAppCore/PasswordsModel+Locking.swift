internal import SunsetCredentials

extension PasswordsModel {
    /// Locks after `minutes` without use; 0: never by itself (`passwords.lockAfter`).
    package func lockAfter(minutes: Double) {
        idle = minutes > 0 ? .seconds(minutes * 60) : nil
    }

    /// Its page was left (`LockWhen`): locked when the settings say so, the edits kept first.
    package func left(_ left: LockWhen.Left) {
        guard lockWhen.locks(left) else { return }
        lock(left == .tab ? .leftTab : .windowInactive)
    }
}
