import Foundation

/// Policy deciding whether Sunset restores saved tabs & terminal history at launch (roadmap 0024 S-3 / t214).
public enum LaunchRestoreDecision: Equatable, Sendable {
    /// Restore immediately without prompting.
    case restoreNow
    /// Do not restore (start fresh).
    case startFresh
    /// Ask the person before restoring (`afterCrash` is true when `session.running` was left behind by a crash).
    case ask(afterCrash: Bool)

    /// Evaluates the configured restore mode and whether the previous run crashed.
    /// After a crash, Sunset **always** asks (even when policy is `.always`) so a crash-looping session cannot trap
    /// the person on relaunch.
    public static func evaluate(
        policy: String,
        crashedLastRun: Bool,
        hasSavedSession: Bool
    ) -> Self {
        guard hasSavedSession else { return .startFresh }
        if crashedLastRun { return .ask(afterCrash: true) }
        switch policy {
            case "never": return .startFresh
            case "ask": return .ask(afterCrash: false)
            default: return .restoreNow
        }
    }
}
