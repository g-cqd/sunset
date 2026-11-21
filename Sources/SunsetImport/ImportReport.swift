/// What an import brought, and what it left out (addresses Sunset does not open, such as `javascript:` bookmarklets and a
/// browser's own pages, and what went past `Favorites.maximumNodes`), for the person to be told.
public struct ImportReport: Sendable, Equatable {
    public var links = 0
    public var folders = 0
    public var leftOut = 0

    public init(links: Int = 0, folders: Int = 0, leftOut: Int = 0) {
        self.links = links
        self.folders = folders
        self.leftOut = leftOut
    }
}
