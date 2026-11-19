import Foundation
import SunsetStorage
import Testing

@testable import SunsetDocuments

/// The files opened lately (roadmap 0031, the owner's answer of 2026-11-16: listed with the documents in the Library). The
/// last twenty, each once, the latest first; sealed in the state database like every small record, so that the names of
/// the person's files are not written in plain.
@MainActor
@Suite("The files opened lately")
struct RecentFilesTests {
    private let path = NSTemporaryDirectory() + "recent-\(UUID().uuidString).sqlite"

    private func table() throws -> SealedTable {
        let key = try StorageKeyring(vault: MemoryKeyVault()).key()
        return try #require(StateDatabase.open(at: path, key: key).database).table("recent-files")
    }

    private func date(_ seconds: Double) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    @Test func `the latest first, each file once, twenty at most`() {
        let recent = RecentFiles(table: nil)
        recent.note("/a/one.md", at: date(1))
        recent.note("/a/two.txt", at: date(2))
        recent.note("/a/one.md", at: date(3))
        #expect(recent.entries.map(\.path) == ["/a/one.md", "/a/two.txt"])
        #expect(recent.entries.first?.opened == date(3))
        for index in 0 ..< 30 { recent.note("/b/\(index).md", at: date(Double(10 + index))) }
        #expect(recent.entries.count == RecentFiles.limit && RecentFiles.limit == 20)
        #expect(recent.entries.first?.path == "/b/29.md" && recent.entries.last?.path == "/b/10.md")
        recent.remove("/b/29.md")
        #expect(recent.entries.first?.path == "/b/28.md" && recent.entries.count == 19)
        recent.clear()
        #expect(recent.entries.isEmpty)
    }

    @Test func `they are kept, sealed: found again at the next start, and no name is in the file`() throws {
        let kept = try table()
        let recent = RecentFiles(table: kept)
        for index in 0 ..< 25 { recent.note("/Users/someone/Secret plans/\(index).md", at: date(Double(index))) }
        recent.remove("/Users/someone/Secret plans/24.md")
        let again = RecentFiles(table: kept)
        #expect(again.entries.count == 19 && kept.count() == 19, "what fell off the end is not kept either")
        #expect(again.entries.first?.path == "/Users/someone/Secret plans/23.md")
        #expect(again.entries.first?.opened == date(23))
        let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
        #expect(bytes.range(of: Data("Secret plans".utf8)) == nil)
        recent.clear()
        #expect(RecentFiles(table: kept).entries.isEmpty)
    }
}
