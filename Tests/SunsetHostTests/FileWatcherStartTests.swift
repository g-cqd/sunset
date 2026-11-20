import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetHost

/// A flaky test (2026-11-17: "a change on disk to a block edited here is kept apart…", two runs of eight): the file was
/// written right after its document was opened, and the change was never told. The watcher opened the file and armed the
/// queue on its own thread, after `start()` returned: a change made before the thread ran was missed. Watched from the
/// moment `start()` returns.
@Suite("File watcher: watched as soon as it is started", .serialized)
struct FileWatcherStartTests {
    @Test func `a change made at once after start is told, each of fifty times`() async throws {
        let directory = NSTemporaryDirectory() + "sunset-watch-start-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: directory) }
        var missed = 0
        for index in 0 ..< 50 {
            let file = directory + "/\(index).md"
            try "base".write(toFile: file, atomically: true, encoding: .utf8)
            let watcher = FileWatcher(path: file, settle: .milliseconds(20))
            watcher.start()
            try "theirs".write(toFile: file, atomically: true, encoding: .utf8)
            let told =
                await withDeadline(within: .seconds(1)) {
                    var changes = watcher.changes.makeAsyncIterator()
                    return await changes.next() != nil
                } ?? false
            if !told { missed += 1 }
            watcher.stop()
        }
        #expect(missed == 0, "\(missed) of 50 changes made at once after start were missed")
    }
}
