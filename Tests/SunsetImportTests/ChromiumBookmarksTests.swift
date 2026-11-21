import Foundation
import Testing

@testable import SunsetImport

/// Chromium's `Bookmarks` file (roadmap 0111 B): the shape Chrome 140 writes, its three roots in their order.
@Suite("Chromium's bookmarks")
struct ChromiumBookmarksTests {
    private let file = Data(
        """
        {
           "checksum": "0f3c",
           "roots": {
              "synced": {
                 "children": [ { "id": "9", "name": "On the phone", "type": "url", "url": "https://example.org/phone" } ],
                 "id": "3", "name": "Mobile bookmarks", "type": "folder"
              },
              "bookmark_bar": {
                 "children": [
                    { "id": "5", "name": "Swift", "type": "url", "url": "https://swift.org/" },
                    { "children": [
                         { "id": "7", "name": "WebKit", "type": "url", "url": "https://webkit.org/" },
                         { "id": "8", "name": "A bookmarklet", "type": "url", "url": "javascript:alert(1)" }
                      ], "id": "6", "name": "Engines", "type": "folder" }
                 ],
                 "id": "1", "name": "Bookmarks bar", "type": "folder"
              },
              "other": { "children": [ ], "id": "2", "name": "Other bookmarks", "type": "folder" }
           },
           "version": 1
        }
        """
        .utf8
    )

    @Test func `the bar's contents come first, then each other root that holds something, as a folder`() throws {
        let nodes = try ChromiumBookmarks.read(file)
        #expect(
            nodes == [
                .link(BookmarkLink(title: "Swift", address: "https://swift.org/")),
                .folder(
                    BookmarkFolder(
                        name: "Engines",
                        children: [
                            .link(BookmarkLink(title: "WebKit", address: "https://webkit.org/")),
                            .link(BookmarkLink(title: "A bookmarklet", address: "javascript:alert(1)"))
                        ]
                    )
                ),
                .folder(
                    BookmarkFolder(
                        name: "Mobile bookmarks",
                        children: [.link(BookmarkLink(title: "On the phone", address: "https://example.org/phone"))]
                    )
                )
            ]
        )
    }

    @Test func `a file that is not Chromium's is refused`() {
        #expect(throws: DecodingError.self) { try ChromiumBookmarks.read(Data("{\"roots\": 3}".utf8)) }
        #expect(throws: DecodingError.self) { try ChromiumBookmarks.read(Data("not json".utf8)) }
    }

    @Test func `a node of a kind it does not know is left out, its siblings kept`() throws {
        let data = Data(
            """
            {"roots": {"bookmark_bar": {"type": "folder", "name": "Bar", "children": [
                {"type": "separator", "name": ""},
                {"type": "url", "name": "Kept", "url": "https://kept.example/"}
            ]}}}
            """
            .utf8
        )
        #expect(
            try ChromiumBookmarks.read(data) == [.link(BookmarkLink(title: "Kept", address: "https://kept.example/"))]
        )
    }
}
