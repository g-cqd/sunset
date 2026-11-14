import Foundation
import Testing

@testable import SunsetStorage

/// Where the time of reading many sealed records goes. Off unless `SUNSET_BENCH=1`; run in release.
@MainActor
@Suite("Reading 50,000 sealed records", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_BENCH"] == "1"))
struct SealBenchTests {
    static func milliseconds(_ body: () -> Void) -> Double {
        let start = ContinuousClock.now
        body()
        let took = ContinuousClock.now - start
        return Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15
    }

    @Test func bench() throws {
        let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0) }))
        let seal = Seal(key: key, purpose: .state)
        let payload = Data(
            "https://site123.example.org/section/45/page-12345.html?ref=7\nPage 12345 about tides, harbours and the North Sea, part 3"
                .utf8
        )
        let sealed = try (0 ..< 50000).map { try seal.seal(payload, identity: "history:\($0)") }
        var opened = 0
        let open = Self.milliseconds {
            for (index, bytes) in sealed.enumerated() where (try? seal.open(bytes, identity: "history:\(index)")) != nil
            {
                opened += 1
            }
        }
        print(String(format: "BENCH seal.open x50000: %.0f ms (%d opened)", open, opened))
        let path = NSTemporaryDirectory() + "sealbench-\(UUID().uuidString)/state.sqlite"
        let database = try #require(StateDatabase.open(at: path, key: key).database)
        let table = database.table("history")
        database.transaction {
            for index in 0 ..< 50000 { table.put("u\(index)", payload: payload, sort: Double(index)) }
        }
        var rows = 0
        let all = Self.milliseconds { rows = table.all().rows.count }
        print(String(format: "BENCH table.all() 50000 rows: %.0f ms (%d rows)", all, rows))
        var raw = 0
        let read = Self.milliseconds {
            database.rows("SELECT key, sealed, sort, count FROM records WHERE kind = 'history'") { _ in raw += 1 }
        }
        print(String(format: "BENCH the query alone: %.0f ms (%d rows)", read, raw))
        let reopen = Self.milliseconds { _ = StateDatabase.open(at: path, key: key) }
        print(String(format: "BENCH database open with its check: %.0f ms", reopen))
    }
}
