public import Foundation

/// The tabs of a window, in order, with the selected one: the single source of truth that the presentations (system tabs, the sidebar, the built-in bar) show.
public struct TabList: Sendable, Equatable {
    public typealias ID = UUID

    public struct Tab: Sendable, Equatable, Identifiable {
        public let id: ID
        public var title: String
        /// The working directory the program reported (OSC 7), if any.
        public var directory: String?
        /// The progress the program reported (OSC 9;4), 0 to 1, if any.
        public var progress: Double?

        public init(id: ID = ID(), title: String, directory: String? = nil, progress: Double? = nil) {
            self.id = id
            self.title = title
            self.directory = directory
            self.progress = progress
        }
    }

    public enum Position: Sendable { case afterSelected, end }

    public private(set) var tabs: [Tab] = []
    public private(set) var selectedID: ID?

    public init() {}

    public var count: Int { tabs.count }
    public var isEmpty: Bool { tabs.isEmpty }
    public var selectedIndex: Int? { selectedID.flatMap { id in tabs.firstIndex { $0.id == id } } }

    /// Adds a tab (selected) after the selected tab, or at the end.
    @discardableResult
    public mutating func add(title: String, after position: Position = .afterSelected) -> ID {
        let tab = Tab(id: ID(), title: title)
        let index: Int
        switch position {
            case .afterSelected: index = (selectedIndex.map { $0 + 1 }) ?? tabs.count
            case .end: index = tabs.count
        }
        tabs.insert(tab, at: index)
        selectedID = tab.id
        return tab.id
    }

    public mutating func select(id: ID) {
        if tabs.contains(where: { $0.id == id }) { selectedID = id }
    }

    public mutating func select(index: Int) {
        if tabs.indices.contains(index) { selectedID = tabs[index].id }
    }

    /// The next tab, the first after the last.
    public mutating func selectNext() {
        guard let index = selectedIndex else { return }
        selectedID = tabs[(index + 1) % tabs.count].id
    }

    /// The previous tab, the last before the first.
    public mutating func selectPrevious() {
        guard let index = selectedIndex else { return }
        selectedID = tabs[(index + tabs.count - 1) % tabs.count].id
    }

    /// Closes a tab. When it was the selected one, its right neighbour is selected, or the left one when it was the last.
    public mutating func close(_ id: ID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = selectedID == id
        tabs.remove(at: index)
        if tabs.isEmpty {
            selectedID = nil
        } else if wasSelected {
            selectedID = tabs[min(index, tabs.count - 1)].id
        }
    }

    public mutating func closeOthers(than id: ID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        tabs.removeAll { $0.id != id }
        selectedID = id
    }

    /// Moves a tab to `index` (brought inside the list); the selection stays on the same tab.
    public mutating func move(_ id: ID, to index: Int) {
        guard let from = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs.remove(at: from)
        tabs.insert(tab, at: min(max(index, 0), tabs.count))
    }

    /// Changes a tab's details; an id that is gone is ignored.
    public mutating func update(_ id: ID, _ change: (inout Tab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        change(&tabs[index])
    }
}
