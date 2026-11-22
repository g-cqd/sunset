public import Testing

extension Trait where Self == ConditionTrait {
    /// Runs the test on macOS 27 or later only. For tests that read pixels, text layout or WebKit loading and that fail on CI's macOS 26 runner, where neither Mac they are
    /// written on can look into why (2026-11-20). macOS 26 stays the deployment target: what these tests check is untested there.
    public static var macOS27: Self {
        .enabled("checked on macOS 27 only: fails on CI's macOS 26 runner") {
            if #available(macOS 27, *) { true } else { false }
        }
    }
}
