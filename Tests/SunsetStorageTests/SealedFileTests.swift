import Foundation
import Testing

@testable import SunsetStorage

@Suite("A file kept sealed: the session")
struct SealedFileTests {
    private let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0) }))
    private let noon = Date(timeIntervalSince1970: 1_794_571_200)
    private var seal: Seal { Seal(key: key, purpose: .session) }

    private func path() -> String { NSTemporaryDirectory() + "sealed-\(UUID().uuidString)/session.sealed" }

    private func text(_ data: Data) -> String? { String(data: data, encoding: .utf8) }

    @Test func `written sealed, read back; the file holds nothing in the clear`() throws {
        let path = path()
        try SealedFile.write(Data("tabs and addresses".utf8), to: path, seal: seal, identity: "session")
        let bytes = try #require(FileManager.default.contents(atPath: path))
        #expect(Seal.isSealed(bytes) && bytes.range(of: Data("addresses".utf8)) == nil)
        #expect(
            SealedFile.read(path, as: "The saved session", seal: seal, identity: "session", decode: text)
                == .value("tabs and addresses")
        )
    }

    @Test func `absent is absent; a plain file from before sealing is still read`() throws {
        let path = path()
        #expect(SealedFile.read(path, as: "S", seal: seal, identity: "session", decode: text) == .absent)
        try StoredFile.write(Data("plain".utf8), to: path)
        #expect(SealedFile.read(path, as: "S", seal: seal, identity: "session", decode: text) == .value("plain"))
    }

    @Test func `sealed with another key: locked, left where it is`() throws {
        let path = path()
        try SealedFile.write(Data("x".utf8), to: path, seal: seal, identity: "session")
        let other = Seal(key: StorageKey(bytes: Data(repeating: 9, count: 32)), purpose: .session)
        let read = SealedFile.read(path, as: "The saved session", seal: other, identity: "session", decode: text)
        guard case .locked(let problem) = read else {
            Issue.record("expected locked, got \(read)")
            return
        }
        #expect(problem.kind == .locked && problem.movedTo == nil && FileManager.default.fileExists(atPath: path))
    }

    @Test func `altered, or holding what does not decode: set aside and said`() throws {
        let path = path()
        try SealedFile.write(Data("x".utf8), to: path, seal: seal, identity: "session")
        var bytes = try #require(FileManager.default.contents(atPath: path))
        bytes[bytes.count - 1] ^= 1
        try StoredFile.write(bytes, to: path)
        let read = SealedFile.read(
            path,
            as: "The saved session",
            seal: seal,
            identity: "session",
            now: noon,
            decode: text
        )
        guard case .damaged(let problem) = read else {
            Issue.record("expected damaged, got \(read)")
            return
        }
        #expect(problem.movedTo?.contains("session.sealed.damaged-2026-11-13") == true)
        try SealedFile.write(Data("y".utf8), to: path, seal: seal, identity: "session")
        let refused = SealedFile.read(path, as: "S", seal: seal, identity: "session", now: noon) { _ in nil as String? }
        guard case .damaged = refused else {
            Issue.record("expected damaged, got \(refused)")
            return
        }
    }
}
