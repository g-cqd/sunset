/// Wrong master passwords slow the next try (ADR-0119): three are free; after the third, the next try waits 1 s, then 2,
/// 4 … up to 30 s; a right one clears it. Kept in memory: Argon2 already costs each try about 0.65 s, and this is against
/// guesses typed or scripted through the app's window.
struct UnlockThrottle {
    private var failures = 0
    private var notBefore: Duration?

    /// How long until a try may be made, at `now` (the runtime's uptime); nil when one may be made now.
    func wait(at now: Duration) -> Duration? {
        guard let notBefore, now < notBefore else { return nil }
        return notBefore - now
    }

    mutating func failed(at now: Duration) {
        failures += 1
        guard failures >= 3 else { return }
        notBefore = now + .seconds(min(1 << min(failures - 3, 5), 30))
    }

    mutating func succeeded() {
        failures = 0
        notBefore = nil
    }
}
