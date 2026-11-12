/// Private windows (web step h).
extension AppActions {
    /// A window whose pages are private, sharing one store in memory unless its selector says otherwise.
    func newPrivateWindow() {
        pendingPrivateWindow = true
        tabParent = nil
        joinsRemaining = 0
        openTerminalWindow()
    }
}
