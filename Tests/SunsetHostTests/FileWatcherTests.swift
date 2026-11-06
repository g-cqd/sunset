import Foundation
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
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = watcher.changes.makeAsyncIterator()
                return await iterator.next() != nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    @Test func `a file written in place is reported`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try await Task.sleep(for: .milliseconds(150))
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
        try await Task.sleep(for: .milliseconds(150))
        try "{ \"a\": 1 }".write(toFile: file, atomically: true, encoding: .utf8)
        #expect(await next(watcher), "the first atomic save")
        try await Task.sleep(for: .milliseconds(150))
        try "{ \"a\": 2 }".write(toFile: file, atomically: true, encoding: .utf8)
        #expect(await next(watcher), "the second one: the new file is watched, not the old")
        watcher.stop()
    }

    @Test func `a file that is created later, and one that is deleted, are reported`() async throws {
        let dir = try directory()
        let file = dir + "/config.json"
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try await Task.sleep(for: .milliseconds(150))
        try "{}".write(toFile: file, atomically: false, encoding: .utf8)
        #expect(await next(watcher), "created")
        try await Task.sleep(for: .milliseconds(150))
        try FileManager.default.removeItem(atPath: file)
        #expect(await next(watcher), "deleted")
        watcher.stop()
    }

    @Test func `a directory that does not exist yet is watched from the nearest one that does`() async throws {
        let dir = try directory()
        let file = dir + "/sunset/config.json"
        let watcher = FileWatcher(path: file, settle: .milliseconds(50))
        watcher.start()
        try await Task.sleep(for: .milliseconds(150))
        try FileManager.default.createDirectory(atPath: dir + "/sunset", withIntermediateDirectories: true)
        #expect(await next(watcher), "the directory appeared")
        try await Task.sleep(for: .milliseconds(150))
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
        try await Task.sleep(for: .milliseconds(150))
        for index in 0 ..< 10 {
            try "{ \"n\": \(index) }".write(toFile: file, atomically: false, encoding: .utf8)
            try await Task.sleep(for: .milliseconds(10))
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
        try await Task.sleep(for: .milliseconds(600))
        #expect(watcher.wakeupCount <= 2, "woke \(watcher.wakeupCount) times")
        let start = ContinuousClock.now
        watcher.stop()
        for await _ in watcher.changes {}
        #expect(ContinuousClock.now - start < .milliseconds(200))
    }
}
