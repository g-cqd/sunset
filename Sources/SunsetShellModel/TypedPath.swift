internal import Foundation

/// A path typed in the command bar (R6, roadmap 0023 step M-f). Only what is plainly a path: from the root, from the home
/// folder (`~/`), or a `file:` address. A name alone is not one: from which folder is not known.
package enum TypedPath {
    /// The file `typed` names, when it is there and is not a folder.
    /// - Parameters:
    ///   - typed: what is in the field.
    ///   - home: the home folder, for `~/`.
    /// - Returns: its path, without `.` and `..`.
    package static func file(_ typed: String, home: String = NSHomeDirectory()) -> String? {
        let text = typed.trimmingCharacters(in: .whitespaces)
        let path: String
        if text.hasPrefix("file://") {
            guard let url = URL(string: text), url.isFileURL else { return nil }
            path = url.path
        } else if text.hasPrefix("~/") {
            path = home + String(text.dropFirst(1))
        } else if text.hasPrefix("/"), !text.hasPrefix("//") {
            path = text
        } else {
            return nil
        }
        let standard = URL(fileURLWithPath: path).standardizedFileURL.path
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standard, isDirectory: &isFolder), !isFolder.boolValue else {
            return nil
        }
        return standard
    }
}
