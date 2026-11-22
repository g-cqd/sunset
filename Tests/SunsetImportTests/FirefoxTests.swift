import Foundation
import Testing

@testable import SunsetImport

/// Firefox's profiles, bookmarks and containers, in the shapes Firefox 145 writes.
@Suite("Firefox")
struct FirefoxTests {
    @Test func `profiles: the install's default first, then the file's order; a path kept as written`() {
        let ini = """
            [Profile1]
            Name=default
            IsRelative=1
            Path=Profiles/aaa.default

            [Install4F96D1932A9F858E]
            Default=Profiles/bbb.default-release
            Locked=1

            [Profile0]
            Name=Work
            IsRelative=1
            Path=Profiles/bbb.default-release
            Default=1

            [General]
            StartWithLastProfile=1

            [Profile2]
            IsRelative=0
            Path=/Volumes/Other/firefox
            """
        #expect(
            FirefoxProfiles.read(ini) == [
                BrowserProfile(folder: "Profiles/bbb.default-release", name: "Work"),
                BrowserProfile(folder: "Profiles/aaa.default", name: "default"),
                BrowserProfile(folder: "/Volumes/Other/firefox", name: "firefox")
            ]
        )
        #expect(FirefoxProfiles.read("").isEmpty)
    }

    private func row(
        _ id: Int,
        in parent: Int,
        at position: Int,
        _ type: Int,
        _ title: String?,
        _ url: String? = nil,
        guid: String = ""
    )
        -> FirefoxBookmarkRow
    {
        FirefoxBookmarkRow(
            id: id,
            parent: parent,
            position: position,
            type: type,
            title: title,
            url: url,
            guid: guid.isEmpty ? "g\(id)" : guid
        )
    }

    @Test func `bookmarks: the toolbar's contents first, then the menu and the others as folders, in position order`() {
        let rows = [
            row(1, in: 0, at: 0, 2, "", guid: "root________"),
            row(2, in: 1, at: 0, 2, "menu", guid: "menu________"),
            row(3, in: 1, at: 1, 2, "toolbar", guid: "toolbar_____"),
            row(4, in: 1, at: 2, 2, "tags", guid: "tags________"),
            row(5, in: 1, at: 3, 2, "unfiled", guid: "unfiled_____"),
            row(6, in: 1, at: 4, 2, "mobile", guid: "mobile______"),
            row(10, in: 3, at: 1, 1, "Second", "https://second.example/"),
            row(11, in: 3, at: 0, 1, "First", "https://first.example/"),
            row(12, in: 3, at: 2, 3, nil),
            row(13, in: 3, at: 3, 2, "Folder"),
            row(14, in: 13, at: 0, 1, nil, "https://untitled.example/"),
            row(20, in: 2, at: 0, 1, "In the menu", "https://menu.example/"),
            row(30, in: 4, at: 0, 2, "a tag"),
            row(31, in: 30, at: 0, 1, nil, "https://tagged.example/")
        ]
        #expect(
            FirefoxBookmarks.tree(rows) == [
                .link(BookmarkLink(title: "First", address: "https://first.example/")),
                .link(BookmarkLink(title: "Second", address: "https://second.example/")),
                .folder(
                    BookmarkFolder(
                        name: "Folder",
                        children: [.link(BookmarkLink(title: "", address: "https://untitled.example/"))]
                    )
                ),
                .folder(
                    BookmarkFolder(
                        name: "Bookmarks Menu",
                        children: [.link(BookmarkLink(title: "In the menu", address: "https://menu.example/"))]
                    )
                )
            ]
        )
    }

    @Test func `bookmarks: a folder that holds itself, or a row whose parent is gone, does not loop or appear`() {
        let rows = [
            row(3, in: 1, at: 0, 2, "toolbar", guid: "toolbar_____"),
            row(7, in: 8, at: 0, 2, "A"),
            row(8, in: 7, at: 0, 2, "B"),
            row(9, in: 3, at: 0, 2, "Loop"),
            row(10, in: 9, at: 0, 2, "Inner"),
            row(9, in: 10, at: 0, 2, "Loop again")
        ]
        #expect(
            FirefoxBookmarks.tree(rows) == [
                .folder(BookmarkFolder(name: "Loop", children: [.folder(BookmarkFolder(name: "Inner"))]))
            ]
        )
    }

    @Test func `containers: the person's, named, with Firefox's colour and icon; its private ones left out`() throws {
        let data = Data(
            """
            {"version": 5, "lastUserContextId": 6, "identities": [
              {"userContextId": 1, "public": true, "icon": "fingerprint", "color": "blue", "l10nId": "user-context-personal", "accessKey": "user-context-personal.accesskey"},
              {"userContextId": 2, "public": true, "icon": "briefcase", "color": "orange", "l10nId": "user-context-work"},
              {"userContextId": 5, "public": false, "icon": "", "color": "", "name": "userContextIdInternal.thumbnail"},
              {"userContextId": 6, "public": true, "icon": "tree", "color": "green", "name": "Garden"}
            ]}
            """
            .utf8
        )
        #expect(
            try FirefoxContainers.read(data) == [
                BrowserContainer(name: "Personal", color: "blue", icon: "fingerprint"),
                BrowserContainer(name: "Work", color: "orange", icon: "briefcase"),
                BrowserContainer(name: "Garden", color: "green", icon: "tree")
            ]
        )
        #expect(throws: DecodingError.self) { try FirefoxContainers.read(Data("[]".utf8)) }
    }
}
