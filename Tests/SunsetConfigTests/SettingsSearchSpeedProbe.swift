import Foundation
import Testing

@testable import SunsetConfig

/// The owner's note n15 (2026-11-18): "the search through settings can be very slow sometimes". What one keystroke costs:
/// the search, then each found option looked up and its topic's scope checked, as the settings page does (`SUNSET_SPEED`:
/// a probe; run it with `-c release`).
@Suite("Searching the settings, timed (probe)")
struct SettingsSearchSpeedProbe {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_SPEED"] != nil))
    func `one keystroke's search, as the page does it`() {
        let entries = SettingsOption.all.map(\.entry)
        let features = Configuration().features
        let queries = ["t", "ta", "tab", "tabs", "s", "si", "sid", "side", "w", "we", "web", "font", "colour", "z"]
        var times: [Double] = []
        for _ in 0 ..< 20 {
            for query in queries {
                let start = ContinuousClock.now
                let found = SettingsSearch.matches(query, in: entries)
                    .compactMap { SettingsOption.named($0.id) }
                    .filter { SettingsSection.showsTopic($0.topic, features) }
                let spent = ContinuousClock.now - start
                times.append(Double(spent.components.attoseconds) / 1e15 + Double(spent.components.seconds) * 1000)
                _ = found.count
            }
        }
        times.sort()
        let median = times[times.count / 2]
        let p90 = times[times.count * 9 / 10]
        print("probe-search: \(entries.count) entries, median \(median) ms, p90 \(p90) ms, max \(times.last ?? 0) ms")
    }
}
