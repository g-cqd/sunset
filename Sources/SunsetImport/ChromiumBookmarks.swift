public import Foundation

/// Chromium's `Bookmarks` file (Chrome, Chromium, Brave, Edge, Vivaldi, Opera, Arc), JSON (roadmap 0111 B).
public enum ChromiumBookmarks {
    /// The file's roots, as Chromium names them: the bar, the other bookmarks, the mobile ones.
    private struct File: Decodable {
        let roots: [String: ChromiumNode]
    }

    /// The roots after the bar, in the order Chrome shows them.
    static let otherRoots = ["other", "synced"]

    /// The tree of a `Bookmarks` file: the bar's contents first, then the other and the mobile bookmarks, each a folder
    /// when it holds something. Throws when the file is not Chromium's.
    public static func read(_ data: Data) throws -> [BookmarkNode] {
        let file = try JSONDecoder().decode(File.self, from: data)
        let bar = file.roots["bookmark_bar"]?.contents ?? []
        let others = otherRoots.compactMap { file.roots[$0] }.filter { !$0.contents.isEmpty }.compactMap(\.bookmark)
        return bar + others
    }
}
