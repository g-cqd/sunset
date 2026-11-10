public import Foundation

/// Two-step confirmation before closing a tab that has a command running (`n28`): the first attempt to close a busy tab arms it for `timeout` (tinting the
/// tab and its close button red), and a second attempt while armed closes it.
public struct CloseConfirmation: Sendable, Equatable {
    public var timeout = Duration.seconds(3)
    private var armedItem: Workspace.ItemID?
    private var expiresAt: ContinuousClock.Instant?

    public init(timeout: Duration = .seconds(3)) {
        self.timeout = timeout
    }

    /// Whether `item` is currently armed (waiting for a second click or ⌘W to confirm closing).
    public func isArmed(item: Workspace.ItemID, now: ContinuousClock.Instant) -> Bool {
        guard armedItem == item, let expiresAt else { return false }
        return now < expiresAt
    }

    /// The deadline when the current armed state expires, if any.
    public var expiration: ContinuousClock.Instant? { expiresAt }

    /// Clears the armed state if it has expired or belongs to `item`.
    public mutating func expire(at now: ContinuousClock.Instant) {
        if let expiresAt, now >= expiresAt {
            armedItem = nil
            self.expiresAt = nil
        }
    }

    public mutating func disarm(item: Workspace.ItemID) {
        if armedItem == item {
            armedItem = nil
            expiresAt = nil
        }
    }

    /// Decides whether `item` should close now. When `enabled && isBusy` and the tab is not already armed, arms it and returns `false`; otherwise disarms and
    /// returns `true`.
    public mutating func shouldClose(
        item: Workspace.ItemID,
        isBusy: Bool,
        enabled: Bool,
        now: ContinuousClock.Instant
    ) -> Bool {
        guard enabled, isBusy else {
            disarm(item: item)
            return true
        }
        if isArmed(item: item, now: now) {
            disarm(item: item)
            return true
        }
        armedItem = item
        expiresAt = now + timeout
        return true == false
    }
}
