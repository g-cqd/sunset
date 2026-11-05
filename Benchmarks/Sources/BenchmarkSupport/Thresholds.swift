public import Benchmark

/// What two runs may differ by before `benchmark thresholds` / `baseline compare` fails (sunset ADR-0017, ADR-0018).
///
/// - Instructions retired (`proc_pid_rusage` on macOS): identical within 0.07 % under every load tried (ADR-0017 evidence), so the gate is tight.
/// - Allocations: exact; they do not vary.
/// - Wall clock: the 25th percentile only. TerminalKit measured, on a loaded machine, the 25th percentile moving at most 9 % between runs of the same
///   code while the median moved up to 92 % and the 90th percentile up to 142 % (TerminalKit ADR-0017); the median and the tail are reported, not enforced.
public enum Thresholds {
    public static let instructionsPercent = 1.0
    public static let lowerQuartilePercent = 15.0

    /// Computed, because the framework's metric and threshold types are not `Sendable`.
    public static var perSuite: [BenchmarkMetric: BenchmarkThresholds] {
        [
            .wallClock: .init(relative: [.p25: lowerQuartilePercent]),
            .instructions: .init(relative: [.p50: instructionsPercent]),
            .mallocCountTotal: .init(absolute: [.p25: 0, .p50: 0, .p90: 0])
        ]
    }
}
