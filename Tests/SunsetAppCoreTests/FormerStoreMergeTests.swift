import Foundation
import SunsetDocuments
import SunsetStorage
import SunsetWebModel
import Testing

@testable import SunsetAppCore

/// ADR-0114: Sunset WebKit's store of before is merged once into the shared one: its documents and its history added, its
/// folder left as it was (a backup). Here with named setups, whose keys are files, never the Keychain.
@MainActor
@Suite("Sunset WebKit's store of before, merged once")
struct FormerStoreMergeTests {
    private func places(_ name: String, in root: URL) throws -> StoragePlaces {
        let folder = root.appending(path: name)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return StoragePlaces(environment: ["SUNSET_SESSION": folder.appending(path: "session.json").path], home: "/")
    }

    /// Every file of `folder` and its bytes.
    private func contents(of folder: String) -> [String: Data] {
        let files = FileManager.default.enumerator(atPath: folder)?.allObjects as? [String] ?? []
        return Dictionary(
            uniqueKeysWithValues: files.compactMap { name in
                FileManager.default.contents(atPath: folder + "/" + name).map { (name, $0) }
            }
        )
    }

    @Test func `its documents and history come in, the same document once; its folder is left as it was`() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "sunset-merge-\(UUID().uuidString)")
        let formerPlaces = try places("former", in: root)
        let former = SunsetStore(places: formerPlaces, problems: StorageProblems()) { false }
        let note = try #require(former.documents).create(text: "# From WebKit\nkept")
        let formerHistory = HistoryStore(table: former.table("history"))
        formerHistory.visit("https://webkit.org/", title: "WebKit", at: Date(timeIntervalSince1970: 2_000))
        formerHistory.visit("https://both.example/", title: "Both", at: Date(timeIntervalSince1970: 3_000))
        former.close()
        let before = contents(of: formerPlaces.directory)

        let current = SunsetStore(places: try places("current", in: root), problems: StorageProblems()) { false }
        let history = HistoryStore(table: current.table("history"))
        history.visit("https://both.example/", title: "Both", at: Date(timeIntervalSince1970: 1_000))
        let merged = FormerStoreMerge.run(
            into: current,
            history: history,
            from: formerPlaces,
            scratch: root.appending(path: "scratch").path
        )
        #expect(merged == FormerStoreMerge.Merged(documents: 1, pages: 2))
        let documents = try #require(current.documents)
        #expect(documents.documents.map(\.id) == [note.id])
        #expect(try documents.text(of: note.id) == "# From WebKit\nkept")
        #expect(history.entries().map(\.url).sorted() == ["https://both.example/", "https://webkit.org/"])
        let both = try #require(history.entries().first { $0.url == "https://both.example/" })
        #expect(both.visits == 2 && both.lastVisit == Date(timeIntervalSince1970: 3_000))
        #expect(contents(of: formerPlaces.directory) == before, "the folder of before untouched")
        // Once only.
        #expect(FormerStoreMerge.run(into: current, history: history, from: formerPlaces, scratch: root.path) == nil)
    }

    @Test func `nothing of before: nothing merged, and nothing made there`() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "sunset-merge-\(UUID().uuidString)")
        let current = SunsetStore(places: try places("current", in: root), problems: StorageProblems()) { false }
        let absent = StoragePlaces(
            environment: ["SUNSET_SESSION": root.appending(path: "none/session.json").path],
            home: "/"
        )
        #expect(FormerStoreMerge.run(into: current, history: nil, from: absent, scratch: root.path) == nil)
        #expect(!FileManager.default.fileExists(atPath: absent.directory))
    }
}
