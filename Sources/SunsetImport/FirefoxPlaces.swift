public import Foundation
import SQLite3

/// Reads `places.sqlite`, the database Firefox keeps its bookmarks in.
public enum FirefoxPlaces {
    /// Why it could not be read.
    public enum Failure: Error, Equatable {
        case unreadable(String)
    }

    static let query = """
        SELECT b.id, b.parent, b.position, b.type, b.title, p.url, b.guid
        FROM moz_bookmarks b LEFT JOIN moz_places p ON p.id = b.fk
        """

    /// The bookmark rows of the database at `file`, read from a copy: Firefox holds the file while it runs, with what it
    /// wrote last still in its write-ahead log (`-wal`), which is copied beside it (SQLite leaves out the log's frames
    /// that do not match the file, should Firefox write between the two copies). Nothing of Firefox's is written.
    public static func rows(of file: URL) throws -> [FirefoxBookmarkRow] {
        let folder = FileManager.default.temporaryDirectory.appending(path: "sunset-import-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        do {
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            let copy = folder.appending(path: "places.sqlite")
            try FileManager.default.copyItem(at: file, to: copy)
            let log = URL(filePath: file.path + "-wal")
            if FileManager.default.fileExists(atPath: log.path) {
                try FileManager.default.copyItem(at: log, to: URL(filePath: copy.path + "-wal"))
            }
            return try read(copy.path)
        } catch let failure as Failure {
            throw failure
        } catch {
            throw Failure.unreadable(error.localizedDescription)
        }
    }

    private static func read(_ path: String) throws -> [FirefoxBookmarkRow] {
        var handle: OpaquePointer?
        defer { unsafe sqlite3_close(handle) }
        guard unsafe sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            throw Failure.unreadable("cannot open")
        }
        var statement: OpaquePointer?
        defer { unsafe sqlite3_finalize(statement) }
        guard unsafe sqlite3_prepare_v2(handle, query, -1, &statement, nil) == SQLITE_OK else {
            throw Failure.unreadable(
                unsafe String(validatingCString: sqlite3_errmsg(handle)) ?? "not a places database"
            )
        }
        var rows: [FirefoxBookmarkRow] = []
        while true {
            let step = unsafe sqlite3_step(statement)
            if step == SQLITE_DONE { return rows }
            guard step == SQLITE_ROW else { throw Failure.unreadable("a row could not be read") }
            rows.append(unsafe row(statement))
        }
    }

    private static func row(_ statement: OpaquePointer?) -> FirefoxBookmarkRow {
        func integer(_ column: Int32) -> Int {
            Int(unsafe sqlite3_column_int64(statement, column))
        }
        func text(_ column: Int32) -> String? {
            guard let bytes = unsafe sqlite3_column_text(statement, column) else { return nil }
            let count = Int(unsafe sqlite3_column_bytes(statement, column))
            return unsafe String(decoding: UnsafeBufferPointer(start: bytes, count: count), as: UTF8.self)
        }
        return FirefoxBookmarkRow(
            id: integer(0),
            parent: integer(1),
            position: integer(2),
            type: integer(3),
            title: text(4),
            url: text(5),
            guid: text(6) ?? ""
        )
    }
}
