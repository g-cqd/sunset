import Foundation
import Testing

/// Waiting for what is not Sunset's to time (ADR-0087): a page WebKit loads, a server's answer, a file the system watches,
/// AppKit laying out and drawing. The only place a test waits on the wall clock; Sunset's own timing is `TestTime`'s.
public enum RealWait {
    /// How often a condition is looked at, and how long at most.
    public static let step = Duration.milliseconds(10)
    public static let limit = Duration.seconds(5)

    /// Looks at `condition` until it holds or `limit` has passed; whether it holds. `Poll.until` says what and where
    /// when it does not: prefer it where a test can throw.
    @MainActor
    @discardableResult
    public static func until(within limit: Duration = limit, _ condition: @MainActor () async -> Bool) async -> Bool {
        (try? await Poll.until(within: limit, every: step) { await condition() }) != nil
    }

    /// The main run loop runs for `duration`: AppKit lays out, draws and delivers what it queued.
    @MainActor
    public static func runLoop(for duration: Duration) {
        let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    /// Real time passes: only for what has no event to wait for (a window server's animation).
    public static func pass(_ duration: Duration) async {
        try? await ContinuousClock().sleep(for: duration)
    }
}
