import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// Task t109 (diary 2026-11-19-08): a list is converted and compiled once, then looked up (under 1 ms) at every launch and
/// every six hours instead of 0.77 s of the main thread and 2.9 s of compiling; a changed list is compiled again; what no
/// list uses any more is removed from WebKit's store.
@MainActor @Suite("Blocking lists: compiled once", .timeLimit(.minutes(1)))
struct ContentBlockerCacheTests {
    @Test func `the same list is compiled once; a changed one again; the old one removed`() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "blocker-cache-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let first = ContentBlocker.Source(
            address: "https://lists.example/a.txt",
            text: "##.banner\n||ads.example^",
            updated: .now
        )
        let blocker = ContentBlocker(folder: folder, pauses: BlockingPauses())
        await blocker.load([first])
        #expect(blocker.compilations == 1)
        let again = ContentBlocker(folder: folder, pauses: BlockingPauses())
        await again.load([first])
        #expect(again.compilations == 0, "a launch with the same list looks it up")
        #expect(again.states.map(\.rules) == [2] && again.states.first?.problem == nil, "its counts kept with it")
        var changed = first
        changed.text += "\n||more.example^"
        await again.load([changed])
        #expect(again.compilations == 1)
        let store = try #require(WKContentRuleListStore(url: folder))
        let identifiers = await store.availableIdentifiers() ?? []
        #expect(identifiers.count == 1, "the list of before is gone: \(identifiers)")
    }
}
