package import Foundation

/// What the system hands Sunset to open, from another app or Finder (the owner's note n18): links to pages, opened as pages,
/// and files, opened as documents. A link of any other kind (`mailto:`, `javascript:`, an app's own) is neither: the system
/// does not send Sunset those it does not claim, and one that comes anyway is dropped.
package enum IncomingLinks {
    package static func split(_ urls: [URL]) -> (pages: [URL], files: [String]) {
        var pages: [URL] = []
        var files: [String] = []
        for url in urls {
            if url.isFileURL {
                files.append(url.path)
            } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                pages.append(url)
            }
        }
        return (pages, files)
    }
}
