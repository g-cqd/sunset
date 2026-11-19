import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A probe, run when `SUNSET_BLOCKING_LISTS` names list files (colon-separated; fetched by hand, never by the tests):
/// each converted and compiled by WebKit, with the time each took and the size compiled (roadmap 0022 W-c).
@MainActor @Suite("Blocking lists compiled by WebKit (probe)", .timeLimit(.minutes(5)))
struct BlockingCompileProbeTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_BLOCKING_LISTS"] != nil))
    func `real lists convert and compile`() async throws {
        let paths = ProcessInfo.processInfo.environment["SUNSET_BLOCKING_LISTS"]?.split(separator: ":") ?? []
        let folder = FileManager.default.temporaryDirectory.appending(path: "blocking-probe-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = try #require(WKContentRuleListStore(url: folder))
        for path in paths {
            let text = try String(contentsOfFile: String(path), encoding: .utf8)
            var converted = BlockingRules.Converted()
            let converting = Stopwatch.time { converted = BlockingRules.convert(text) }
            let json = String(decoding: try BlockingRules.json(converted.rules), as: UTF8.self)
            let start = Stopwatch()
            let list = try await store.compileContentRuleList(forIdentifier: "probe", encodedContentRuleList: json)
            let compiling = start.elapsed
            let size = try FileManager.default
                .contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])
                .compactMap { try $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
            print(
                "probe \(path): \(converted.rules.count) rules, \(converted.skipped) left out; converted in \(converting),"
                    + " compiled in \(compiling); JSON \(json.utf8.count / 1024) KB, compiled \(size / 1024) KB"
            )
            #expect(list != nil)
            try await store.removeContentRuleList(forIdentifier: "probe")
        }
    }
}
