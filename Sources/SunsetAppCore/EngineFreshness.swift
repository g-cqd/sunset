public import Foundation

/// How old Sunset WebKit's engine is (threat model D10): WebKit publishes security fixes every five to seven weeks, which
/// macOS updates do not bring to the WebKit inside the app.
public enum EngineFreshness {
    /// The Info.plist key the build writes: the date of the WebKit base, ISO 8601.
    public static let dateKey = "SunsetWebKitBaseDate"
    /// From this age the engine has likely missed a round of fixes.
    public static let behindAfterWeeks = 8

    /// Whole weeks from `base` to `now`; nil when the build records no date (the native build).
    public static func weeks(base: Date?, now: Date) -> Int? {
        base.map { max(0, Int(now.timeIntervalSince($0) / (7 * 86_400))) }
    }

    /// Whether to tell the person now: the engine is behind, and they were not told already for this base.
    public static func tells(weeks: Int?, base: String?, toldFor: String?) -> Bool {
        guard let weeks, let base else { return false }
        return weeks >= behindAfterWeeks && base != toldFor
    }
}
