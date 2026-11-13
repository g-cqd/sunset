import Foundation
import Testing

@testable import SunsetStorage

@Suite("A file Sunset keeps: written whole, and never dropped silently")
struct StoredFileTests {
    private func folder() -> String {
        NSTemporaryDirectory() + "stored-\(UUID().uuidString)"
    }

    private let noon = Date(timeIntervalSince1970: 1_794_571_200)

    @Test func `a write makes the folder, replaces the file, and leaves nothing else there`() throws {
        let folder = folder()
        let path = folder + "/deep/session.json"
        try StoredFile.write(Data("one".utf8), to: path)
        try StoredFile.write(Data("two".utf8), to: path, durability: .forced)
        #expect(FileManager.default.contents(atPath: path) == Data("two".utf8))
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder + "/deep") == ["session.json"])
    }

    @Test func `a write that cannot be done says so and leaves the old file`() throws {
        let folder = folder()
        let path = folder + "/session.json"
        try StoredFile.write(Data("kept".utf8), to: path)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder) }
        #expect(throws: StorageFailure.self) { try StoredFile.write(Data("lost".utf8), to: path) }
        #expect(FileManager.default.contents(atPath: path) == Data("kept".utf8))
    }

    @Test func `a file that is not there is absent; one that reads is its value`() throws {
        let path = folder() + "/a.json"
        #expect(StoredFile.read(path, as: "The session") { String(data: $0, encoding: .utf8) } == .absent)
        try StoredFile.write(Data("hello".utf8), to: path)
        #expect(StoredFile.read(path, as: "The session") { String(data: $0, encoding: .utf8) } == .value("hello"))
    }

    @Test func `a file that does not read is moved aside under a dated name, and said; it is not read again`() throws {
        let folder = folder()
        let path = folder + "/session.json"
        try StoredFile.write(Data("{ not json".utf8), to: path)
        let read = StoredFile.read(path, as: "The saved session", now: noon) { _ in nil as Int? }
        guard case .damaged(let problem) = read else {
            Issue.record("expected a damaged file, got \(read)")
            return
        }
        #expect(problem.what == "The saved session" && problem.path == path)
        let aside = try #require(problem.movedTo)
        #expect(
            aside.hasPrefix(folder + "/session.json.damaged-2026-11-13")
                && !FileManager.default.fileExists(atPath: path)
        )
        #expect(FileManager.default.contents(atPath: aside) == Data("{ not json".utf8), "nothing of it is lost")
        #expect(StoredFile.read(path, as: "The saved session", now: noon) { _ in nil as Int? } == .absent)
    }

    @Test func `two files set aside in the same second get two names`() throws {
        let folder = folder()
        let path = folder + "/s.json"
        try StoredFile.write(Data("a".utf8), to: path)
        let first = try #require(StoredFile.moveAside(path, now: noon))
        try StoredFile.write(Data("b".utf8), to: path)
        let second = try #require(StoredFile.moveAside(path, now: noon))
        #expect(first != second && FileManager.default.contents(atPath: second) == Data("b".utf8))
    }

    @Test @MainActor func `what went wrong is kept to be said, once each, and can be dismissed`() {
        let problems = StorageProblems()
        let problem = StorageProblem(
            what: "The saved session",
            path: "/x/session.json",
            movedTo: "/x/session.json.damaged-1"
        )
        problems.report(problem)
        problems.report(problem)
        #expect(problems.items == [problem])
        #expect(
            problem.sentence == "The saved session could not be read. It was moved aside as session.json.damaged-1."
        )
        problems.dismiss(problem)
        #expect(problems.items.isEmpty)
    }
}
