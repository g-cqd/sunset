/// A node of Chromium's `Bookmarks` file as it is written: a folder (`children`) or a link (`url`), or a kind this does
/// not read (a separator), which `bookmark` leaves out.
struct ChromiumNode: Decodable {
    let type: String
    let name: String?
    let url: String?
    let children: [Self]?

    /// The node as a bookmark; nil for a kind that is neither a folder nor a link.
    var bookmark: BookmarkNode? {
        switch type {
            case "url": url.map { .link(BookmarkLink(title: name ?? "", address: $0)) }
            case "folder": .folder(BookmarkFolder(name: name ?? "", children: contents))
            default: nil
        }
    }

    var contents: [BookmarkNode] {
        (children ?? []).compactMap(\.bookmark)
    }
}
