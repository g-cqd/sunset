public import Foundation

/// Safari's `Bookmarks.plist` (roadmap 0111 E), which macOS lets an app read only with Full Disk Access.
public enum SafariBookmarks {
    /// Why it could not be read.
    public enum Failure: Error, Equatable {
        case notSafari
    }

    /// The lists Safari names by key, and the names it shows.
    static let bar = "BookmarksBar"
    static let readingList = "com.apple.ReadingList"
    static let shown = ["BookmarksMenu": "Bookmarks Menu", readingList: "Reading List"]

    /// The tree: the Favorites bar's contents first, then the Bookmarks Menu and the other lists as folders when they
    /// hold something, the Reading List last; History is not a bookmark.
    public static func read(_ data: Data) throws -> [BookmarkNode] {
        let root = try? PropertyListSerialization.propertyList(from: data, format: nil)
        guard let root = root as? [String: Any], root["WebBookmarkType"] as? String == "WebBookmarkTypeList" else {
            throw Failure.notSafari
        }
        let lists = (root["Children"] as? [[String: Any]] ?? [])
            .filter { $0["WebBookmarkType"] as? String == "WebBookmarkTypeList" }
        let title = { (list: [String: Any]) in list["Title"] as? String ?? "" }
        let barContents = lists.filter { title($0) == bar }.flatMap(children)
        let others =
            lists.filter { title($0) != bar && title($0) != readingList }
            + lists.filter { title($0) == readingList }
        let folders = others.compactMap { list -> BookmarkNode? in
            let held = children(of: list)
            return held.isEmpty ? nil : .folder(BookmarkFolder(name: shown[title(list)] ?? title(list), children: held))
        }
        return barContents + folders
    }

    private static func children(of list: [String: Any]) -> [BookmarkNode] {
        (list["Children"] as? [[String: Any]] ?? []).compactMap(node)
    }

    private static func node(_ item: [String: Any]) -> BookmarkNode? {
        switch item["WebBookmarkType"] as? String {
            case "WebBookmarkTypeLeaf":
                guard let address = item["URLString"] as? String, !address.isEmpty else { return nil }
                let title = (item["URIDictionary"] as? [String: Any])?["title"] as? String ?? ""
                return .link(BookmarkLink(title: title, address: address))
            case "WebBookmarkTypeList":
                return .folder(BookmarkFolder(name: item["Title"] as? String ?? "", children: children(of: item)))
            default:
                return nil
        }
    }
}
