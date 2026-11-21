import Testing

@testable import SunsetImport

/// The exported bookmarks file (roadmap 0111 C), as Safari, Chrome and Firefox write it.
@Suite("Exported bookmarks files")
struct NetscapeBookmarksTests {
    @Test func `folders and links in order, names and addresses unescaped, tags in any case and left open`() {
        let text = """
            <!DOCTYPE NETSCAPE-Bookmark-file-1>
            <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
            <TITLE>Bookmarks</TITLE>
            <H1>Bookmarks</H1>
            <DL><p>
                <DT><H3 ADD_DATE="1700000000" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks bar</H3>
                <DL><p>
                    <DT><A HREF="https://swift.org/" ADD_DATE="1700000000" ICON="data:image/png;base64,AAAA">Swift &amp; more</A>
                    <dt><h3>Engines</h3>
                    <dl><p>
                        <dt><a href='https://webkit.org/?a=1&amp;b=2'>WebKit</a>
                    </dl><p>
                </DL><p>
                <DT><A HREF="https://example.org/">  Example  </A>
                <HR>
            </DL><p>
            """
        #expect(
            NetscapeBookmarks.read(text) == [
                .folder(
                    BookmarkFolder(
                        name: "Bookmarks bar",
                        children: [
                            .link(BookmarkLink(title: "Swift & more", address: "https://swift.org/")),
                            .folder(
                                BookmarkFolder(
                                    name: "Engines",
                                    children: [
                                        .link(BookmarkLink(title: "WebKit", address: "https://webkit.org/?a=1&b=2"))
                                    ]
                                )
                            )
                        ]
                    )
                ),
                .link(BookmarkLink(title: "Example", address: "https://example.org/"))
            ]
        )
    }

    @Test func `a file cut short keeps what it has; one with no bookmarks has none`() {
        let cut = "<DL><p><DT><H3>Open</H3><DL><p><DT><A HREF=\"https://a.example/\">A</A>"
        #expect(
            NetscapeBookmarks.read(cut) == [
                .folder(
                    BookmarkFolder(
                        name: "Open",
                        children: [.link(BookmarkLink(title: "A", address: "https://a.example/"))]
                    )
                )
            ]
        )
        #expect(NetscapeBookmarks.read("<html><body>nothing</body></html>").isEmpty)
        #expect(NetscapeBookmarks.read("").isEmpty)
    }

    @Test func `more closing than opening, and a link without an address, do not lose the rest`() {
        let text = "</DL></DL><DT><A>none</A><DT><A HREF=\"https://b.example/\">B</A>"
        #expect(NetscapeBookmarks.read(text) == [.link(BookmarkLink(title: "B", address: "https://b.example/"))])
    }
}
