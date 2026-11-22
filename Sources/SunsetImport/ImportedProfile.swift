/// What one profile of another browser holds that Sunset imports.
public struct ImportedProfile: Sendable, Equatable {
    public var bookmarks: [BookmarkNode]
    public var extensions: [BrowserExtension]
    public var containers: [BrowserContainer]

    public init(
        bookmarks: [BookmarkNode] = [],
        extensions: [BrowserExtension] = [],
        containers: [BrowserContainer] = []
    ) {
        self.bookmarks = bookmarks
        self.extensions = extensions
        self.containers = containers
    }
}
