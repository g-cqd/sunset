import Foundation
import SQLite3

/// The history file of before the state database (`history.sqlite`: one table, in the clear), read once (R12 step ST-3).
extension HistoryStore {
    /// Takes in the pages of the file at `path`; says how many it held, or nil when there is no such file or it does not read.
    /// The file is not touched: whoever calls removes it once the pages are kept.
    package func importLegacy(at path: String) -> Int? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        var handle: OpaquePointer?
        defer { unsafe sqlite3_close(handle) }
        var statement: OpaquePointer?
        guard unsafe sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
            unsafe sqlite3_prepare_v2(handle, "SELECT url, title, visits, last FROM pages", -1, &statement, nil)
                == SQLITE_OK
        else { return nil }
        defer { unsafe sqlite3_finalize(statement) }
        var entries: [HistoryEntry] = []
        while unsafe sqlite3_step(statement) == SQLITE_ROW {
            guard let url = unsafe sqlite3_column_text(statement, 0) else { continue }
            let title = unsafe sqlite3_column_text(statement, 1)
            entries.append(
                HistoryEntry(
                    url: unsafe String(cString: url),
                    title: unsafe title.map { unsafe String(cString: $0) } ?? "",
                    visits: Int(unsafe sqlite3_column_int64(statement, 2)),
                    lastVisit: Date(timeIntervalSince1970: unsafe sqlite3_column_double(statement, 3))
                )
            )
        }
        adopt(entries)
        return entries.count
    }
}
