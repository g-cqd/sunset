public import Foundation

/// Which hidden pages let go of their memory now (roadmap 0021 S-f, ADR-0071): those hidden longer than the delay; and
/// while memory is short, the one hidden the longest, one at a time. Never one on screen nor one that is exempt (plays,
/// captures, is kept awake, is pinned). Decided from what it is given, at the time it is given: no clock of its own.
package enum PageSleep {
    package struct Candidate: Sendable, Equatable {
        /// Since when it is not on screen; nil while it is.
        package var hiddenSince: Date?
        package var exempt: Bool

        package init(hiddenSince: Date?, exempt: Bool) {
            self.hiddenSince = hiddenSince
            self.exempt = exempt
        }
    }

    /// - Parameters:
    ///   - candidates: the loaded pages.
    ///   - now: the time it is.
    ///   - unloadAfter: the delay in hours (`web.unloadAfter`); 0, never by the delay.
    ///   - pressure: macOS says memory is short.
    ///   - unloadsUnderPressure: `web.unloadUnderPressure`.
    /// - Returns: the indices of the pages to unload, in `candidates`' order.
    package static func choose(
        _ candidates: [Candidate],
        now: Date,
        unloadAfter: Double,
        pressure: Bool,
        unloadsUnderPressure: Bool = true
    ) -> [Int] {
        let idle = candidates.indices.compactMap { index -> (index: Int, since: Date)? in
            guard !candidates[index].exempt, let since = candidates[index].hiddenSince else { return nil }
            return (index, since)
        }
        var chosen = Set<Int>()
        if unloadAfter > 0 {
            for page in idle where now.timeIntervalSince(page.since) >= unloadAfter * 3600 { chosen.insert(page.index) }
        }
        if pressure, unloadsUnderPressure, chosen.isEmpty,
            let oldest = idle.min(by: { $0.since < $1.since })
        {
            chosen.insert(oldest.index)
        }
        return chosen.sorted()
    }

    /// Whether macOS's memory pressure level (`kern.memorystatus_vm_pressure_level`: 1 normal, 2 warning, 4 critical) says
    /// memory is short: critical only (ADR-0076). The warning level held for minutes with half the memory free.
    package static func memoryIsShort(level: Int32) -> Bool {
        level >= 4
    }
}
