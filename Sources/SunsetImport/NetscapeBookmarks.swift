/// The bookmarks file every browser exports (`NETSCAPE-Bookmark-file-1`, HTML; roadmap 0111 C): the "any other browser"
/// path.
public enum NetscapeBookmarks {
    /// The tree the file holds. Its markup is loose (tags left open, any case), so this reads only what bookmarks need:
    /// `<H3>` names a folder whose `<DL>` follows, `<A HREF>` is a link, `</DL>` closes a folder. A file cut short keeps
    /// what it has.
    public static func read(_ text: String) -> [BookmarkNode] {
        var tree = Tree()
        var rest = text[...]
        while let open = rest.firstIndex(of: "<") {
            let inside = rest[rest.index(after: open)...]
            guard let close = inside.firstIndex(of: ">") else { break }
            rest = inside[inside.index(after: close)...]
            guard let tag = MarkupTag(inside[..<close]) else { continue }
            switch (tag.name, tag.isClosing) {
                case ("h3", false): tree.folderName = MarkupText.title(contents(of: "h3", in: &rest))
                case ("dl", false): tree.openList()
                case ("dl", true): tree.closeList()
                case ("a", false):
                    let title = MarkupText.title(contents(of: "a", in: &rest))
                    if let address = tag.attributes["href"], !address.isEmpty {
                        tree.add(.link(BookmarkLink(title: title, address: address)))
                    }
                default: continue
            }
        }
        return tree.finished()
    }

    /// The text up to the next tag, which is skipped when it is `</name>` (a title holds no markup in these files).
    private static func contents(of name: String, in rest: inout Substring) -> Substring {
        let stop = rest.firstIndex(of: "<") ?? rest.endIndex
        let text = rest[..<stop]
        rest = rest[stop...]
        let closing = "</" + name + ">"
        if rest.prefix(closing.count).lowercased() == closing { rest = rest.dropFirst(closing.count) }
        return text
    }
}
