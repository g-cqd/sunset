extension BookmarkNode {
    /// This node and every one under it.
    var count: Int {
        switch self {
            case .link: 1
            case .folder(let folder): 1 + folder.children.reduce(0) { $0 + $1.count }
        }
    }
}
