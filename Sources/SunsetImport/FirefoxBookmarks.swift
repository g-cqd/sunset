/// Firefox's bookmarks, from `places.sqlite`.
public enum FirefoxBookmarks {
    /// The roots after the toolbar, in the order Firefox shows them, with the names it shows (the rows' own are internal).
    static let otherRoots = [
        ("menu________", "Bookmarks Menu"), ("unfiled_____", "Other Bookmarks"), ("mobile______", "Mobile Bookmarks")
    ]

    /// The tree the rows make: the toolbar's contents first, then the menu, the other and the mobile bookmarks, each a
    /// folder when it holds something; tags are not bookmarks. A folder is read once: a row that would bring it back
    /// (a damaged file) is left out.
    public static func tree(_ rows: [FirefoxBookmarkRow]) -> [BookmarkNode] {
        let children = Dictionary(grouping: rows, by: \.parent).mapValues { $0.sorted { $0.position < $1.position } }
        let roots = Dictionary(rows.map { ($0.guid, $0.id) }) { first, _ in first }
        var seen: Set<Int> = []
        func contents(of id: Int) -> [BookmarkNode] {
            guard seen.insert(id).inserted else { return [] }
            return (children[id] ?? [])
                .compactMap { row in
                    switch row.type {
                        case FirefoxBookmarkRow.link:
                            row.url.map { .link(BookmarkLink(title: row.title ?? "", address: $0)) }
                        case FirefoxBookmarkRow.folder:
                            seen.contains(row.id)
                                ? nil : .folder(BookmarkFolder(name: row.title ?? "", children: contents(of: row.id)))
                        default: nil
                    }
                }
        }
        let toolbar = roots["toolbar_____"].map(contents) ?? []
        let others = otherRoots.compactMap { guid, name -> BookmarkNode? in
            guard let id = roots[guid] else { return nil }
            let held = contents(of: id)
            return held.isEmpty ? nil : .folder(BookmarkFolder(name: name, children: held))
        }
        return toolbar + others
    }
}
