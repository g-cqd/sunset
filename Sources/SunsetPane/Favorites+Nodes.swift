public import Foundation

extension Favorites {
    /// One thing in the tree.
    public enum Node: Sendable, Equatable, Identifiable {
        case folder(Folder)
        case entry(Entry)

        public var id: NodeID {
            switch self {
                case .folder(let folder): folder.id
                case .entry(let entry): entry.id
            }
        }
    }

    /// A synthetic folder (`n40`): not a directory on disk.
    public struct Folder: Sendable, Equatable, Identifiable {
        public let id: NodeID
        public internal(set) var name: String
        public internal(set) var icon: PaneIcon?
        public internal(set) var isCollapsed: Bool
        public internal(set) var children: [Node]

        init(
            id: NodeID = NodeID(),
            name: String,
            icon: PaneIcon? = nil,
            isCollapsed: Bool = false,
            children: [Node] = []
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.isCollapsed = isCollapsed
            self.children = children
        }
    }

    /// A kept entry: what it starts from, and its live tab while it is open.
    public struct Entry: Sendable, Equatable, Identifiable {
        public let id: NodeID
        /// The user's name for it; nil shows its content's title.
        public internal(set) var title: String?
        public internal(set) var icon: PaneIcon?
        public internal(set) var home: Home
        public internal(set) var open: Workspace.Item?

        public var isOpen: Bool { open != nil }

        init(
            id: NodeID = NodeID(),
            title: String? = nil,
            icon: PaneIcon? = nil,
            home: Home,
            open: Workspace.Item? = nil
        ) {
            self.id = id
            self.title = title
            self.icon = icon
            self.home = home
            self.open = open
        }
    }

    /// What an entry starts from each time it is opened: the layout it was kept with, and what brings the content of each pane back.
    public struct Home: Sendable, Equatable {
        public let layout: SplitLayout
        public let focused: PaneID
        public let contents: [PaneID: PaneDescriptor]

        /// Only the panes of the layout have content. A layout that names a pane twice, or a focused pane that is not in it, does not hold together.
        public init(layout: SplitLayout, focused: PaneID, contents: [PaneID: PaneDescriptor] = [:]) {
            let panes = Set(layout.panes)
            self.layout = layout
            self.focused = focused
            self.contents = contents.filter { panes.contains($0.key) }
        }

        var holdsTogether: Bool {
            let panes = layout.panes
            return panes.contains(focused) && Set(panes).count == panes.count
        }
    }

    /// Where a node is in the tree.
    public struct Location: Sendable, Equatable {
        /// The folder that holds it; nil at the top.
        public let parent: NodeID?
        public let index: Int
        /// How many folders are above it.
        public let level: Int
    }

    /// One row of a sidebar.
    public struct Row: Sendable, Equatable, Identifiable {
        public let id: NodeID
        public let level: Int
        public let isFolder: Bool
    }
}
