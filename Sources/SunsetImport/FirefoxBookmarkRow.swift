/// A row of Firefox's `moz_bookmarks`, joined to its address in `moz_places`.
public struct FirefoxBookmarkRow: Sendable, Equatable {
    /// `moz_bookmarks.type`: 1 a link, 2 a folder, 3 a separator.
    public static let link = 1
    public static let folder = 2

    public var id: Int
    public var parent: Int
    public var position: Int
    public var type: Int
    public var title: String?
    public var url: String?
    public var guid: String

    public init(id: Int, parent: Int, position: Int, type: Int, title: String?, url: String?, guid: String) {
        self.id = id
        self.parent = parent
        self.position = position
        self.type = type
        self.title = title
        self.url = url
        self.guid = guid
    }
}
