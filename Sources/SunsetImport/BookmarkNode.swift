/// One thing in a bookmark tree read from another browser: what every importer gives, whatever the browser's own
/// format, and what becomes Sunset's Favorites.
public enum BookmarkNode: Sendable, Equatable {
    case folder(BookmarkFolder)
    case link(BookmarkLink)
}
