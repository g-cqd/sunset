package import Foundation

/// Detects clickable file paths and optional `:line[:column]` suffixes in terminal viewport text (M-h / t211),
/// resolving relative paths against the terminal's OSC 7 working directory and verifying the file exists on disk.
package struct TerminalPathDetector: Sendable, Equatable {
    /// A resolved file target under a terminal cell.
    package struct Match: Sendable, Equatable {
        package let url: URL
        package let line: Int?
        package let column: Int?
    }

    /// Extracts a candidate token at `column` within `lineText`, resolves it relative to `workingDirectory` (or `~`
    /// via `homeDirectory`), and returns a `Match` when the resolved regular file exists on disk.
    package static func detect(
        in lineText: String,
        at column: Int,
        workingDirectory: String?,
        homeDirectory: String = NSHomeDirectory(),
        fileExists: (String) -> Bool = { path in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
        }
    ) -> Match? {
        guard let token = token(in: lineText, at: column) else { return nil }
        let (rawPath, line, col) = splitLineColumn(token)
        guard !rawPath.isEmpty, looksLikePath(rawPath) else { return nil }
        guard let resolved = resolve(rawPath, workingDirectory: workingDirectory, homeDirectory: homeDirectory) else {
            return nil
        }
        guard fileExists(resolved) else { return nil }
        return Match(url: URL(fileURLWithPath: resolved), line: line, column: col)
    }

    /// Extracts the whitespace/delimiter-bounded token covering UTF-16/column offset `column`, trimming wrapping quotes
    /// or brackets (`(...)`, `[...]`, `<...>`, `"..."`, `'...'`, trailing punctuation `,`, `;`).
    static func token(in text: String, at column: Int) -> String? {
        let chars = Array(text)
        guard column >= 0, column < chars.count else { return nil }
        guard !isTokenDelimiter(chars[column]) else { return nil }
        var start = column
        while start > 0, !isTokenDelimiter(chars[start - 1]) { start -= 1 }
        var end = column + 1
        while end < chars.count, !isTokenDelimiter(chars[end]) { end += 1 }
        var slice = String(chars[start ..< end])
        while let first = slice.first, "\"'([<`".contains(first) { slice.removeFirst() }
        while let last = slice.last, "\"')]>,;`.".contains(last) { slice.removeLast() }
        return slice.isEmpty ? nil : slice
    }

    private static func isTokenDelimiter(_ ch: Character) -> Bool {
        ch.isWhitespace || ch == "\"" || ch == "'" || ch == "`" || ch == "(" || ch == ")" || ch == "[" || ch == "]"
            || ch == "<" || ch == ">" || ch == "," || ch == ";"
    }

    /// Splits `path:line:column` or `path:line` from the right when trailing colon-separated components are positive ints.
    static func splitLineColumn(_ token: String) -> (path: String, line: Int?, column: Int?) {
        let parts = token.split(separator: ":", omittingEmptySubsequences: false)
        if parts.count >= 3,
            let col = Int(parts[parts.count - 1]), col > 0,
            let line = Int(parts[parts.count - 2]), line > 0
        {
            let path = parts.dropLast(2).joined(separator: ":")
            return (path, line, col)
        }
        if parts.count >= 2, let line = Int(parts[parts.count - 1]), line > 0 {
            let path = parts.dropLast().joined(separator: ":")
            return (path, line, nil)
        }
        return (token, nil, nil)
    }

    private static func looksLikePath(_ path: String) -> Bool {
        guard !path.contains("://") else { return false }
        return path.contains("/") || path.hasPrefix("~") || path.contains(".")
    }

    private static func resolve(_ raw: String, workingDirectory: String?, homeDirectory: String) -> String? {
        let expanded: String
        if raw == "~" {
            expanded = homeDirectory
        } else if raw.hasPrefix("~/") {
            expanded = homeDirectory + String(raw.dropFirst())
        } else if raw.hasPrefix("/") {
            expanded = raw
        } else if let cwd = workingDirectory, !cwd.isEmpty {
            let base = cwd.hasSuffix("/") ? cwd : cwd + "/"
            expanded = base + raw
        } else {
            return nil
        }
        return URL(fileURLWithPath: expanded).standardizedFileURL.path
    }
}
