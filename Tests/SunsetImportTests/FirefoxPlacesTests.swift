import Foundation
import SQLite3
import Testing

@testable import SunsetImport

/// `places.sqlite` read from a copy: what Firefox has written is read, its log included, while Firefox still has the
/// file open, and the file is left as it was.
@Suite("Firefox's places database")
struct FirefoxPlacesTests {
    private static let schema = """
        PRAGMA journal_mode=WAL;
        CREATE TABLE moz_places (id INTEGER PRIMARY KEY, url LONGVARCHAR, title LONGVARCHAR);
        CREATE TABLE moz_bookmarks (id INTEGER PRIMARY KEY, type INTEGER, fk INTEGER DEFAULT NULL, parent INTEGER,
            position INTEGER, title LONGVARCHAR, guid TEXT);
        INSERT INTO moz_bookmarks VALUES (1, 2, NULL, 0, 0, '', 'root________');
        INSERT INTO moz_bookmarks VALUES (3, 2, NULL, 1, 1, 'toolbar', 'toolbar_____');
        INSERT INTO moz_places VALUES (100, 'https://swift.org/', 'Swift.org');
        INSERT INTO moz_bookmarks VALUES (10, 1, 100, 3, 0, 'Swift', 'aaaaaaaaaaaa');
        """

    /// A database as Firefox leaves it while it runs: in WAL mode, open, its last writes not yet in the file.
    private func firefoxRunning(in folder: URL) throws -> OpaquePointer? {
        var handle: OpaquePointer?
        let path = folder.appending(path: "places.sqlite").path
        #expect(unsafe sqlite3_open(path, &handle) == SQLITE_OK)
        #expect(unsafe sqlite3_exec(handle, Self.schema, nil, nil, nil) == SQLITE_OK)
        #expect(unsafe sqlite3_exec(handle, "PRAGMA wal_autocheckpoint=0;", nil, nil, nil) == SQLITE_OK)
        #expect(
            unsafe sqlite3_exec(
                handle,
                "INSERT INTO moz_bookmarks VALUES (11, 2, NULL, 3, 1, 'Later', 'bbbbbbbbbbbb');",
                nil,
                nil,
                nil
            ) == SQLITE_OK
        )
        return unsafe handle
    }

    @Test func `the rows with their addresses, the log's included, while Firefox has the file open`() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "places-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let handle = try firefoxRunning(in: folder)
        defer { unsafe sqlite3_close(handle) }
        let file = folder.appending(path: "places.sqlite")
        let before = try Data(contentsOf: file)
        let rows = try FirefoxPlaces.rows(of: file)
        #expect(
            rows.contains(
                FirefoxBookmarkRow(
                    id: 10,
                    parent: 3,
                    position: 0,
                    type: 1,
                    title: "Swift",
                    url: "https://swift.org/",
                    guid: "aaaaaaaaaaaa"
                )
            )
        )
        #expect(rows.contains { $0.id == 11 && $0.title == "Later" && $0.url == nil })
        #expect(rows.count == 4)
        #expect(try Data(contentsOf: file) == before)
        #expect(
            try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted() == [
                "places.sqlite", "places.sqlite-shm", "places.sqlite-wal"
            ]
        )
    }

    @Test func `a file that is not a places database is refused`() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: "not-places-\(UUID().uuidString).sqlite")
        try Data("not a database".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(throws: FirefoxPlaces.Failure.self) { try FirefoxPlaces.rows(of: file) }
        #expect(throws: FirefoxPlaces.Failure.self) { try FirefoxPlaces.rows(of: file.appending(path: "missing")) }
    }
}
