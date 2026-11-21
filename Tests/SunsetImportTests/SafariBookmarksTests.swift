import Foundation
import Testing

@testable import SunsetImport

/// Safari's `Bookmarks.plist` (roadmap 0111 E), in the shape Safari 26 writes (binary, as on disk).
@Suite("Safari's bookmarks")
struct SafariBookmarksTests {
    private func leaf(_ title: String, _ url: String) -> [String: Any] {
        [
            "WebBookmarkType": "WebBookmarkTypeLeaf", "URLString": url, "URIDictionary": ["title": title],
            "WebBookmarkUUID": UUID().uuidString
        ]
    }

    private func list(_ title: String, _ children: [[String: Any]]) -> [String: Any] {
        ["WebBookmarkType": "WebBookmarkTypeList", "Title": title, "Children": children]
    }

    private func file(_ root: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
    }

    @Test func `the bar's contents first, then the menu and other lists, the Reading List last; History left out`()
        throws
    {
        let root = list(
            "",
            [
                ["WebBookmarkType": "WebBookmarkTypeProxy", "Title": "History", "WebBookmarkIdentifier": "History"],
                list("com.apple.ReadingList", [leaf("Later", "https://later.example/")]),
                list(
                    "BookmarksBar",
                    [leaf("Swift", "https://swift.org/"), list("Engines", [leaf("WebKit", "https://webkit.org/")])]
                ),
                list("BookmarksMenu", [leaf("In the menu", "https://menu.example/")]),
                list("Mine", [leaf("Kept", "https://kept.example/")]),
                list("Empty", [])
            ]
        )
        #expect(
            try SafariBookmarks.read(file(root)) == [
                .link(BookmarkLink(title: "Swift", address: "https://swift.org/")),
                .folder(
                    BookmarkFolder(
                        name: "Engines",
                        children: [.link(BookmarkLink(title: "WebKit", address: "https://webkit.org/"))]
                    )
                ),
                .folder(
                    BookmarkFolder(
                        name: "Bookmarks Menu",
                        children: [.link(BookmarkLink(title: "In the menu", address: "https://menu.example/"))]
                    )
                ),
                .folder(
                    BookmarkFolder(
                        name: "Mine",
                        children: [.link(BookmarkLink(title: "Kept", address: "https://kept.example/"))]
                    )
                ),
                .folder(
                    BookmarkFolder(
                        name: "Reading List",
                        children: [.link(BookmarkLink(title: "Later", address: "https://later.example/"))]
                    )
                )
            ]
        )
    }

    @Test func `a leaf without a title keeps its address; one without an address is left out`() throws {
        let root = list(
            "",
            [
                list(
                    "BookmarksBar",
                    [
                        ["WebBookmarkType": "WebBookmarkTypeLeaf", "URLString": "https://untitled.example/"],
                        ["WebBookmarkType": "WebBookmarkTypeLeaf", "URIDictionary": ["title": "Nowhere"]]
                    ]
                )
            ]
        )
        #expect(
            try SafariBookmarks.read(file(root)) == [
                .link(BookmarkLink(title: "", address: "https://untitled.example/"))
            ]
        )
    }

    @Test func `a file that is not Safari's is refused`() throws {
        #expect(throws: SafariBookmarks.Failure.self) { try SafariBookmarks.read(Data("not a plist".utf8)) }
        let array = try PropertyListSerialization.data(fromPropertyList: [1, 2], format: .binary, options: 0)
        #expect(throws: SafariBookmarks.Failure.self) { try SafariBookmarks.read(array) }
    }
}
