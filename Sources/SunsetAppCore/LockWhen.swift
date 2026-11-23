/// When the vault locks besides its idle time (`passwords.lockOnLeavingTab`, `passwords.lockOnWindowBlur`).
package struct LockWhen: Equatable, Sendable {
    package var leavingTab: Bool
    package var windowInactive: Bool

    package init(leavingTab: Bool, windowInactive: Bool) {
        self.leavingTab = leavingTab
        self.windowInactive = windowInactive
    }

    /// What the vault's page was left for.
    package enum Left: Sendable {
        /// Another tab of its window was chosen.
        case tab
        /// Its window is no longer the one in front.
        case window
    }

    /// Whether leaving so locks it.
    package func locks(_ left: Left) -> Bool {
        switch left {
            case .tab: leavingTab
            case .window: windowInactive
        }
    }
}
