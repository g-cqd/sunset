import Foundation
import SQLite3

/// The few SQLite calls the database needs: a statement with bound values, run, or read as rows.
extension StateDatabase {
    enum Value {
        case text(String)
        case real(Double)
        case integer(Int)
        case blob(Data)
    }

    @discardableResult
    func run(_ sql: String) -> Bool {
        unsafe sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK
    }

    @discardableResult
    func execute(_ sql: String, _ values: [Value] = []) -> Bool {
        guard let prepared = prepare(sql, values) else { return false }
        defer { unsafe sqlite3_finalize(prepared) }
        return unsafe sqlite3_step(prepared) == SQLITE_DONE
    }

    /// Each row of a query, given to `row` while the statement is on it.
    func rows(_ sql: String, _ values: [Value] = [], _ row: (OpaquePointer) -> Void) {
        guard let prepared = prepare(sql, values) else { return }
        defer { unsafe sqlite3_finalize(prepared) }
        while unsafe sqlite3_step(prepared) == SQLITE_ROW { unsafe row(prepared) }
    }

    func number(_ sql: String, _ values: [Value] = []) -> Int? {
        var found: Int?
        rows(sql, values) { found = Int(unsafe sqlite3_column_int64($0, 0)) }
        return found
    }

    func text(_ sql: String) -> String? {
        var found: String?
        rows(sql) { statement in
            if let text = unsafe sqlite3_column_text(statement, 0) { found = unsafe String(cString: text) }
        }
        return found
    }

    func blob(_ sql: String, _ values: [Value] = []) -> Data? {
        var found: Data?
        rows(sql, values) { found = unsafe Self.data($0, 0) }
        return found
    }

    static func data(_ statement: OpaquePointer, _ column: Int32) -> Data {
        let count = Int(unsafe sqlite3_column_bytes(statement, column))
        guard count > 0, let bytes = unsafe sqlite3_column_blob(statement, column) else { return Data() }
        return unsafe Data(bytes: bytes, count: count)
    }

    private func prepare(_ sql: String, _ values: [Value]) -> OpaquePointer? {
        var prepared: OpaquePointer?
        guard unsafe sqlite3_prepare_v2(handle, sql, -1, &prepared, nil) == SQLITE_OK else { return nil }
        // SQLite copies what is bound at once (SQLITE_TRANSIENT).
        let transient = unsafe unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            switch value {
                case .text(let text): unsafe sqlite3_bind_text(prepared, position, text, -1, transient)
                case .real(let number): unsafe sqlite3_bind_double(prepared, position, number)
                case .integer(let number): unsafe sqlite3_bind_int64(prepared, position, Int64(number))
                case .blob(let data):
                    _ = unsafe data.withUnsafeBytes { bytes in
                        unsafe sqlite3_bind_blob(prepared, position, bytes.baseAddress, Int32(bytes.count), transient)
                    }
            }
        }
        return unsafe prepared
    }
}
