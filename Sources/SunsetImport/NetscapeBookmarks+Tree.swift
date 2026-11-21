extension NetscapeBookmarks {
    /// The folders being read, the innermost last, and the lists that opened none (the file's own, a stray `<DL>`).
    struct Tree {
        private var top: [BookmarkNode] = []
        private var open: [BookmarkFolder] = []
        /// For each `<DL>` not yet closed, whether it opened a folder.
        private var lists: [Bool] = []
        /// The name of the folder whose list comes next.
        var folderName: String?

        mutating func add(_ node: BookmarkNode) {
            if open.isEmpty { top.append(node) } else { open[open.count - 1].children.append(node) }
        }

        mutating func openList() {
            if let name = folderName {
                open.append(BookmarkFolder(name: name))
                lists.append(true)
            } else {
                lists.append(false)
            }
            folderName = nil
        }

        mutating func closeList() {
            guard let openedFolder = lists.popLast(), openedFolder, let folder = open.popLast() else { return }
            add(.folder(folder))
        }

        /// What was read, the folders still open closed.
        mutating func finished() -> [BookmarkNode] {
            while let folder = open.popLast() { add(.folder(folder)) }
            return top
        }
    }
}
