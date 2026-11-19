import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetWeb

/// The cost of the history store with many pages (R12 step ST-3: measured before and after it moved to sealed records searched
/// in memory). Off unless `SUNSET_BENCH=1`; run in release: `SUNSET_BENCH=1 swift test -c release --filter HistoryBench`.
@MainActor
@Suite("History with 50,000 pages", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_BENCH"] == "1"))
struct HistoryBenchTests {
    static let pages = 50000

    static func percentiles(_ samples: [Double]) -> String {
        let sorted = samples.sorted()
        func at(_ share: Double) -> Double {
            sorted[min(Int(Double(sorted.count) * share), sorted.count - 1)]
        }
        return String(format: "p50 %.3f ms, p90 %.3f ms, p99 %.3f ms", at(0.5), at(0.9), at(0.99))
    }

    static func milliseconds(_ body: () -> Void) -> Double {
        let start = Stopwatch()
        body()
        let took = start.elapsed
        return Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15
    }

    static func address(_ index: Int) -> String {
        "https://site\(index % 4000).example.org/section/\(index % 97)/page-\(index).html?ref=\(index % 13)"
    }

    static func title(_ index: Int) -> String {
        "Page \(index) about tides, harbours and the North Sea, part \(index % 31)"
    }

    @Test func bench() async throws {
        let path = NSTemporaryDirectory() + "bench-\(UUID().uuidString)/history"
        let fill = Self.milliseconds {
            guard let store = HistoryBench.open(path) else { return }
            HistoryBench.fill(store, count: Self.pages)
        }
        print(String(format: "BENCH fill %d pages: %.0f ms", Self.pages, fill))
        let before = HistoryBench.footprint()
        var store = HistoryBench.open(path)
        await store?.ready()
        let held = HistoryBench.footprint() - before
        var stalls: [Double] = []
        var opens: [Double] = []
        for _ in 0 ..< 5 {
            let start = Stopwatch()
            stalls.append(Self.milliseconds { store = HistoryBench.open(path) })
            await store?.ready()
            let took = start.elapsed
            opens.append(Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15)
        }
        print("BENCH open, the main actor held:", Self.percentiles(stalls))
        print("BENCH open, until all is read:", Self.percentiles(opens))
        print(String(format: "BENCH memory held by the open store: %.1f MB", Double(held) / 1_048_576))
        let history = try #require(store)
        let needles = ["site12", "tides", "page-4999", "north sea", "zzzz", "example", "part 7", "harb"]
        let search = (0 ..< 200)
            .map { index in
                Self.milliseconds { _ = history.entries(matching: needles[index % needles.count], limit: 200) }
            }
        print("BENCH entries(matching:):", Self.percentiles(search))
        let suggest = (0 ..< 200)
            .map { index in
                Self.milliseconds { _ = history.suggestions(for: needles[index % needles.count]) }
            }
        print("BENCH suggestions(for:):", Self.percentiles(suggest))
        let recent = (0 ..< 50).map { _ in Self.milliseconds { _ = history.entries() } }
        print("BENCH entries() latest 500:", Self.percentiles(recent))
        let visits = (0 ..< 300)
            .map { index in
                Self.milliseconds { history.visit(Self.address(index * 7), title: Self.title(index)) }
            }
        print("BENCH visit:", Self.percentiles(visits))
        let size = HistoryBench.bytes(path)
        print(String(format: "BENCH on disk: %.1f MB", Double(size) / 1_048_576))
    }
}
