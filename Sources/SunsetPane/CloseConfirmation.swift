public import Foundation

/// Two-step confirmation before closing something that has a command running (`n28`): the first attempt arms it for `timeout` (its tab and close button go
/// red), and the same attempt again while armed closes it. What is confirmed is exactly what was asked: agreeing to close one pane does not agree to close
/// its tab, and agreeing to close a tab does not agree to close the others.
public struct CloseConfirmation: Sendable, Equatable {
    /// What a close would take away.
    public enum Target: Sendable, Equatable {
        case pane(PaneID, in: Workspace.ItemID)
        case item(Workspace.ItemID)
        /// Every tab but this one.
        case others(Workspace.ItemID)
    }

    public var timeout = Duration.seconds(3)
    private var armed: Target?
    private var expiresAt: ContinuousClock.Instant?

    public init(timeout: Duration = .seconds(3)) {
        self.timeout = timeout
    }

    /// Whether the tab `item` is among what the armed close would take (it is shown in red).
    public func isArmed(item: Workspace.ItemID, now: ContinuousClock.Instant) -> Bool {
        guard let armed, let expiresAt, now < expiresAt else { return false }
        switch armed {
            case .pane(_, let owner): return owner == item
            case .item(let target): return target == item
            case .others(let kept): return kept != item
        }
    }

    /// When what is armed stops being so, if anything is.
    public var expiration: ContinuousClock.Instant? { expiresAt }

    /// Forgets what is armed once its time has passed.
    public mutating func expire(at now: ContinuousClock.Instant) {
        if let expiresAt, now >= expiresAt { disarm() }
    }

    /// Forgets what is armed when it is `target` (it closed, or went by itself).
    public mutating func disarm(_ target: Target) {
        if armed == target { disarm() }
    }

    public mutating func disarm() {
        armed = nil
        expiresAt = nil
    }

    /// Whether `target` closes now. A busy one, with the confirmation `enabled`, is armed the first time (`false`) and closes when asked again in time.
    public mutating func shouldClose(
        _ target: Target,
        isBusy: Bool,
        enabled: Bool,
        now: ContinuousClock.Instant
    ) -> Bool {
        if !enabled || !isBusy || (armed == target && (expiresAt.map { now < $0 } ?? false)) {
            disarm(target)
            return true
        }
        armed = target
        expiresAt = now + timeout
        return false
    }
}
