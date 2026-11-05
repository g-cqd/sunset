public import Benchmark

/// What two runs may differ by before `benchmark thresholds` / `baseline compare` fails (sunset ADR-0017, ADR-0018, ADR-0019).
///
/// - Instructions retired (`proc_pid_rusage` on macOS): identical in all 16 benchmarks between two contended runs of the same code (load average 25-32 plus
///   eight spinning threads), so the gate is tight.
/// - Allocations: exact; they do not differ.
/// - Wall clock: **not gated** (ADR-0019). On the same contended machine its 25th percentile differed by -44 % to +56 % between two runs of identical code,
///   so any threshold would fail or pass at random. It is reported and compared by a person within one sitting.
public enum Thresholds {
    public static let instructionsPercent = 1.0

    /// Computed, because the framework's metric and threshold types are not `Sendable`.
    public static var perSuite: [BenchmarkMetric: BenchmarkThresholds] {
        [
            .instructions: .init(relative: [.p50: instructionsPercent]),
            .mallocCountTotal: .init(absolute: [.p25: 0, .p50: 0, .p90: 0])
        ]
    }
}
