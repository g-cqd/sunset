/// A bookmark folder of another browser's: its name and what it holds, in order.
public struct BookmarkFolder: Sendable, Equatable {
    public var name: String
    public var children: [BookmarkNode]

    public init(name: String, children: [BookmarkNode] = []) {
        self.name = name
        self.children = children
    }
}
