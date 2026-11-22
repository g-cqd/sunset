public import Foundation
import SQLite3

/// What Sunset's SQLite files share (the state database, the vaults): their folder made their owner's only, and values
/// bound to a statement by copy.
public enum SQLiteBinding {
    /// A value bound to a statement's place.
    public enum Value: Sendable {
        case text(String)
        case real(Double)
        case integer(Int)
        case blob(Data)
    }

    /// The folder of `path` made, or set, 0700.
    public static func ownFolder(of path: String) {
        let folder = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(
            atPath: folder,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder)
    }

    /// `sql` prepared on `handle` with `values` bound in order (SQLite copies them at once: SQLITE_TRANSIENT); nil when it
    /// does not prepare.
    public static func prepare(_ sql: String, _ values: [Value], on handle: OpaquePointer?) -> OpaquePointer? {
        var prepared: OpaquePointer?
        guard unsafe sqlite3_prepare_v2(handle, sql, -1, &prepared, nil) == SQLITE_OK else { return nil }
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
