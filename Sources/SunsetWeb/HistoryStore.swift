package import Foundation
import SQLite3

/// The history of pages visited (web step e), in a SQLite file beside the session (the system's library; not encrypted, R1's store study comes
/// later). One table: an address, its title, its visit count and its last visit. Read and written on the main actor: each call is one small
/// statement.
@MainActor
package final class HistoryStore {
    private var database: OpaquePointer?
    /// Something was written (a visit, a title, a deletion): lists that show the history read it again.
    package var onChange: () -> Void = {}

    /// Opens (or makes) the file at `path`; ":memory:" for one that is never written.
    package init?(path: String) {
        if path != ":memory:" {
            try? FileManager.default.createDirectory(
                at: URL(fileURLWithPath: path).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        guard unsafe sqlite3_open(path, &database) == SQLITE_OK else { return nil }
        let made = run(
            "CREATE TABLE IF NOT EXISTS pages (url TEXT PRIMARY KEY, title TEXT NOT NULL, visits INTEGER NOT NULL, last REAL NOT NULL);"
                + "CREATE INDEX IF NOT EXISTS pages_last ON pages(last);"
        )
        guard made else { return nil }
    }

    isolated deinit { unsafe sqlite3_close(database) }

    /// A visit to `url` at `time`: counted, its title kept when it has one.
    package func visit(_ url: String, title: String, at time: Date = Date()) {
        statement(
            "INSERT INTO pages (url, title, visits, last) VALUES (?1, ?2, 1, ?3) ON CONFLICT(url) DO UPDATE SET visits = visits + 1, "
                + "last = ?3, title = CASE WHEN ?2 = '' THEN title ELSE ?2 END",
            [.text(url), .text(title), .real(time.timeIntervalSince1970)]
        )
        onChange()
    }

    /// The page's title arrived after its visit was counted.
    package func retitle(_ url: String, title: String) {
        guard !title.isEmpty else { return }
        statement("UPDATE pages SET title = ?2 WHERE url = ?1", [.text(url), .text(title)])
        onChange()
    }

    /// The pages whose address or title holds `text` (all when empty), latest first, at most `limit`.
    package func entries(matching text: String = "", limit: Int = 500) -> [HistoryEntry] {
        let pattern = "%" + text.replacingOccurrences(of: "%", with: "") + "%"
        return query(
            "SELECT url, title, visits, last FROM pages WHERE url LIKE ?1 OR title LIKE ?1 ORDER BY last DESC LIMIT ?2",
            [.text(pattern), .integer(limit)]
        )
    }

    /// The best matches for what is typed in an address field: by frecency, those whose host or title starts with it first.
    package func suggestions(for text: String, limit: Int = 4, now: Date = Date()) -> [HistoryEntry] {
        let typed = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !typed.isEmpty else { return [] }
        let found = entries(matching: typed, limit: 200)
        func prefix(_ entry: HistoryEntry) -> Bool {
            let host = URL(string: entry.url)?.host()?.lowercased() ?? ""
            let bare = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            return bare.hasPrefix(typed) || host.hasPrefix(typed) || entry.title.lowercased().hasPrefix(typed)
        }
        return Array(
            found.sorted { left, right in
                let (l, r) = (prefix(left), prefix(right))
                return l != r ? l : left.score(now: now) > right.score(now: now)
            }
            .prefix(limit)
        )
    }

    /// The last `limit` pages visited.
    package func recent(limit: Int = 10) -> [HistoryEntry] { entries(limit: limit) }

    package func delete(_ url: String) {
        statement("DELETE FROM pages WHERE url = ?1", [.text(url)])
        onChange()
    }

    /// Forgets the pages last visited since `date` (all for `.distantPast`).
    package func clear(since date: Date) {
        statement("DELETE FROM pages WHERE last >= ?1", [.real(date.timeIntervalSince1970)])
        onChange()
    }

    /// Forgets the pages last visited before `date` (what `web.history.keep` no longer keeps).
    package func expire(before date: Date) {
        statement("DELETE FROM pages WHERE last < ?1", [.real(date.timeIntervalSince1970)])
    }

    // MARK: SQLite

    enum Value {
        case text(String)
        case real(Double)
        case integer(Int)
    }

    @discardableResult
    private func run(_ sql: String) -> Bool { unsafe sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK }

    @discardableResult
    private func statement(_ sql: String, _ values: [Value]) -> Bool {
        guard let prepared = prepare(sql, values) else { return false }
        defer { unsafe sqlite3_finalize(prepared) }
        return unsafe sqlite3_step(prepared) == SQLITE_DONE
    }

    private func query(_ sql: String, _ values: [Value]) -> [HistoryEntry] {
        guard let prepared = prepare(sql, values) else { return [] }
        defer { unsafe sqlite3_finalize(prepared) }
        var rows: [HistoryEntry] = []
        while unsafe sqlite3_step(prepared) == SQLITE_ROW {
            rows.append(
                HistoryEntry(
                    url: unsafe String(cString: sqlite3_column_text(prepared, 0)),
                    title: unsafe String(cString: sqlite3_column_text(prepared, 1)),
                    visits: Int(unsafe sqlite3_column_int64(prepared, 2)),
                    lastVisit: Date(timeIntervalSince1970: unsafe sqlite3_column_double(prepared, 3))
                )
            )
        }
        return rows
    }

    private func prepare(_ sql: String, _ values: [Value]) -> OpaquePointer? {
        var prepared: OpaquePointer?
        guard unsafe sqlite3_prepare_v2(database, sql, -1, &prepared, nil) == SQLITE_OK else { return nil }
        // SQLite copies the text at once (SQLITE_TRANSIENT).
        let transient = unsafe unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            switch value {
                case .text(let text): unsafe sqlite3_bind_text(prepared, position, text, -1, transient)
                case .real(let number): unsafe sqlite3_bind_double(prepared, position, number)
                case .integer(let number): unsafe sqlite3_bind_int64(prepared, position, Int64(number))
            }
        }
        return unsafe prepared
    }
}
