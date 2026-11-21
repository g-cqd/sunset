/// A bookmark of another browser's: its name there and its address as written (not yet checked: what Sunset can open is
/// decided when it becomes a Favorite).
public struct BookmarkLink: Sendable, Equatable {
    public var title: String
    public var address: String

    public init(title: String, address: String) {
        self.title = title
        self.address = address
    }
}
