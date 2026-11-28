internal import Foundation

/// What shows a file of the person's: a viewer for what is only looked at, a document for what has text.
extension PaneDescriptor {
    /// A file that is only looked at: a PDF, a picture, a sound or a film.
    public static let fileViewKind = "file"

    /// What shows the file at `path`: its viewer when it is only looked at (`isViewed`), else its document.
    public static func forFile(_ path: String) -> PaneDescriptor {
        isViewed(path: path) ? PaneDescriptor(kind: fileViewKind, state: ["file": path]) : .document(file: path)
    }

    /// Whether the file at `path` is only looked at in Sunset, by its extension: a PDF, a picture, a sound or a film.
    public static func isViewed(path: String) -> Bool {
        FileViewed(extension: (path as NSString).pathExtension) != nil
    }
}
