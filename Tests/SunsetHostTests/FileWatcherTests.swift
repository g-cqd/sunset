import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetHost

@Suite("File watcher", .serialized) struct FileWatcherTests {
    private func directory() throws -> String {
        let path = NSTemporaryDirectory() + "sunset-watch-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    /// Waits for the next event for at most `seconds`.
    private func next(_ watcher: FileWatcher, seconds: Double = 2) async -> Bool {
        await withDeadline(within: .seconds(seconds)) {
            var iterator = watcher.changes.makeAsyncIterator()
            return await iterator.next() != nil
        } ?? false
    }

    @Test func `a file written in place is reported`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try "{ \"a\": 1 }".write(toFile: file, atomically: false, encoding: .utf8)
        #expect(await next(watcher))
        watcher.stop()
    }

    @Test func `an atomic save, which replaces the file, is reported, and so is the one after it`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try "{ \"a\": 1 }".write(toFile: file, atomically: true, encoding: .utf8)
        #expect(await next(watcher), "the first atomic save")
        try "{ \"a\": 2 }".write(toFile: file, atomically: true, encoding: .utf8)
        #expect(await next(watcher), "the second one: the new file is watched, not the old")
        watcher.stop()
    }

    @Test func `a file that is created later, and one that is deleted, are reported`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        #expect(await next(watcher), "created")
        try FileManager.default.removeItem(atPath: file)
        #expect(await next(watcher), "deleted")
        watcher.stop()
    }

    @Test func `a directory that does not exist yet is watched from the nearest one that does`() async throws {
        let dir = try directory()
        let file = dir + "/sunset/config.json"
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try FileManager.default.createDirectory(atPath: dir + "/sunset", withIntermediateDirectories: true)
        #expect(await next(watcher), "the directory appeared")
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        #expect(await next(watcher), "the file appeared in it")
        watcher.stop()
    }

    @Test func `a burst of writes is one event`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        let watcher = FileWatcher(path: file, settle: .milliseconds(120))
        watcher.start()
        for index in 0 ..< 10 {
            try "{ \"n\": \(index) }".write(toFile: file, atomically: false, encoding: .utf8)
            // The burst is spread over time, inside one settle: the pacing is the test's input, not a wait.
            await RealWait.pass(.milliseconds(10))
        }
        #expect(await next(watcher))
        #expect(await next(watcher, seconds: 0.5) == false, "no second event for the same burst")
        watcher.stop()
    }

    @Test func `nothing happening costs no wake-ups, and stopping ends the stream at once`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        let watcher = FileWatcher(path: file)
        watcher.start()
        // Nothing is to happen for a while: only time passing says so.
        await RealWait.pass(.milliseconds(600))
        #expect(watcher.wakeupCount <= 2, "woke \(watcher.wakeupCount) times")
        let watch = Stopwatch()
        watcher.stop()
        for await _ in watcher.changes {}
        // Stopping is prompt, not a poll's timeout later: no count says that.
        #expect(watch.elapsed < .milliseconds(200))
    }
}
