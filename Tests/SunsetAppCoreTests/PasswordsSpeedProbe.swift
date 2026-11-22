import Foundation
import SunsetCredentials
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// What the vault costs as it grows (a probe, run by hand in release: SUNSET_PASSWORDS_PROBE=1): a save, and what a
/// sign-in reads (the entries and the sites never to save for), with 1,000 entries; p50, p90 and p99 of 30 runs.
@MainActor
@Suite("Passwords' cost, measured", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_PASSWORDS_PROBE"] != nil))
struct PasswordsSpeedProbe {
    private func percentiles(_ samples: [Double]) -> String {
        let sorted = samples.sorted()
        let at = { (share: Double) in sorted[min(sorted.count - 1, Int(Double(sorted.count) * share))] }
        return String(format: "p50 %.2f ms, p90 %.2f ms, p99 %.2f ms", at(0.5), at(0.9), at(0.99))
    }

    private func milliseconds(_ body: () throws -> Void) rethrows -> Double {
        let spent = try Stopwatch.time(body)
        return Double(spent.components.attoseconds) / 1e15 + Double(spent.components.seconds) * 1000
    }

    @Test func `a save and a sign-in's reads, with 1,000 entries`() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "speed-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = PasswordsModel(
            path: folder.appending(path: "v.vault").path,
            cost: MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1),
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        _ = try model.create(password: "correct horse battery", again: "correct horse battery")
        for index in 0 ..< 1_000 { _ = try model.add(from: .login, title: "Entry \(index)") }
        var saves: [Double] = []
        var reads: [Double] = []
        for index in 0 ..< 30 {
            var entry = model.entries[index]
            entry.title += "!"
            saves.append(try milliseconds { try model.save(entry) })
            reads.append(milliseconds { _ = (model.entries.count, model.neverSave.count) })
        }
        var searches: [Double] = []
        for query in ["e", "en", "ent", "entr", "entry", "entry 9", "entry 99"] {
            for _ in 0 ..< 5 { searches.append(milliseconds { _ = EntrySearch.matching(query, in: model.entries) }) }
        }
        print("PROBE search a keystroke:", percentiles(searches))
        print("PROBE save:", percentiles(saves))
        print("PROBE sign-in reads:", percentiles(reads))
    }
}
