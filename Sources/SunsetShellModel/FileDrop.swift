/// A file dropped on the window (R6, roadmap 0023 step M-f, ADR-0040). On a terminal its path is typed for the program
/// there, as in every terminal; anywhere else each file opens as a document, and a folder does nothing.
///
/// A dropped name is not the person's typing: it can come from an archive or a download. Inside single quotes a shell reads
/// nothing of it, but its line editor still acts on control characters (an interrupt ends the line, and what follows is
/// then typed as a command), so a name that holds one is never typed.
package enum FileDrop {
    package enum Outcome: Equatable, Sendable {
        /// Typed into the terminal, as a paste.
        case type(String)
        /// Opened as documents.
        case open([String])
        case nothing
    }

    /// What a drop of `paths` does.
    /// - Parameters:
    ///   - paths: the files and folders dropped.
    ///   - onTerminal: whether they were dropped on a terminal pane.
    ///   - isFolder: whether a path is a folder.
    /// - Returns: the text to type, the files to open, or nothing.
    package static func outcome(of paths: [String], onTerminal: Bool, isFolder: (String) -> Bool) -> Outcome {
        if onTerminal { return typed(paths).map(Outcome.type) ?? .nothing }
        let files = paths.filter { !isFolder($0) }
        return files.isEmpty ? .nothing : .open(files)
    }

    /// The paths as a shell reads them, each followed by a space; nil when there is none, or when any holds a control
    /// character.
    package static func typed(_ paths: [String]) -> String? {
        guard !paths.isEmpty, paths.allSatisfy(isSafe) else { return nil }
        return paths.map { quoted($0) + " " }.joined()
    }

    /// What a paste types: the copied files' paths as a drop types them, not the name a file manager puts beside them as text
    /// (the owner, 2026-11-21); the text itself when no file was copied. Nil when there is nothing to paste, or when a copied
    /// file's name would not be typed for a drop.
    package static func pasted(files: [String], text: String?) -> String? {
        files.isEmpty ? text : typed(files)
    }

    /// No control character (C0, DEL, C1) and no line or paragraph separator.
    private static func isSafe(_ path: String) -> Bool {
        path.unicodeScalars.allSatisfy { scalar in
            scalar.value >= 0x20 && !(0x7F ... 0x9F).contains(scalar.value) && scalar.value != 0x2028
                && scalar.value != 0x2029
        }
    }

    /// As it is when it is only letters, digits and `/ . _ - + , : @ %`; else in single quotes.
    private static func quoted(_ path: String) -> String {
        let plain = path.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII
                && (scalar.properties.isAlphabetic || ("0" ... "9").contains(scalar)
                    || "/._-+,:@%".unicodeScalars.contains(scalar))
        }
        return plain ? path : "'" + path.replacing("'", with: #"'\''"#) + "'"
    }
}
