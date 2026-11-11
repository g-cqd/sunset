public import Foundation

/// The tabs of a window, in order, with the selected one: the single source of truth that the presentations (system tabs, the sidebar, the built-in bar)
/// show. A tab (an `Item`) holds one pane, or several arranged in a split layout (`Workspace+Splits`); each pane belongs to exactly one tab.
///
/// It is a value and knows nothing of what a pane shows (a terminal, later a web page): the panes are identities, and the owner keeps their content. Closing
/// operations return the panes that went, so that the owner can stop them.
public struct Workspace: Sendable, Equatable {
    public typealias ItemID = UUID

    /// One tab: a layout of panes and the pane that has the keyboard.
    public struct Item: Sendable, Equatable, Identifiable {
        public let id: ItemID
        public internal(set) var layout: SplitLayout
        public internal(set) var focused: PaneID
        /// A custom user-specified title overriding the content's title (`n41`).
        public internal(set) var customTitle: String?
        /// A custom icon (SF Symbol or emoji) overriding the content's default glyph (`n41`).
        public internal(set) var customIcon: PaneIcon?

        public var panes: [PaneID] { layout.panes }
        /// More than one pane.
        public var isSplit: Bool { panes.count > 1 }

        init(
            id: ItemID = ItemID(),
            layout: SplitLayout,
            focused: PaneID,
            customTitle: String? = nil,
            customIcon: PaneIcon? = nil
        ) {
            self.id = id
            self.layout = layout
            self.focused = focused
            self.customTitle = customTitle
            self.customIcon = customIcon
        }
    }

    public enum Position: Sendable { case afterSelected, end }

    public internal(set) var items: [Item] = []
    public internal(set) var selectedID: ItemID?
    /// The kept entry this window shows instead of one of its own tabs (`Favorites`). The window's selected tab stays behind it: it is what shows again
    /// when the entry is unloaded. Selecting a tab leaves the entry.
    public internal(set) var selectedEntry: Favorites.NodeID?

    public init() {}

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }
    public var selectedIndex: Int? { selectedID.flatMap { id in items.firstIndex { $0.id == id } } }
    public var selectedItem: Item? { selectedIndex.map { items[$0] } }
    /// The pane that has the keyboard: the focused pane of the selected tab.
    public var selectedPane: PaneID? { selectedItem?.focused }
    /// Every pane of every tab, in tab order.
    public var allPanes: [PaneID] { items.flatMap(\.panes) }

    public func item(containing pane: PaneID) -> Item? { items.first { $0.layout.contains(pane) } }

    /// Adds a tab with one new pane, selected, after the selected tab or at the end.
    @discardableResult
    public mutating func add(after position: Position = .afterSelected) -> (item: ItemID, pane: PaneID) {
        let pane = PaneID()
        let item = Item(layout: .pane(pane), focused: pane)
        let index: Int
        switch position {
            case .afterSelected: index = selectedIndex.map { $0 + 1 } ?? items.count
            case .end: index = items.count
        }
        items.insert(item, at: index)
        show(item.id)
        return (item.id, pane)
    }

    public mutating func select(item id: ItemID) {
        if items.contains(where: { $0.id == id }) { show(id) }
    }

    public mutating func select(index: Int) {
        if items.indices.contains(index) { show(items[index].id) }
    }

    /// Shows a kept entry in this window, or (nil) the window's own selected tab again.
    public mutating func select(entry id: Favorites.NodeID?) { selectedEntry = id }

    /// Selects one of the window's own tabs, which leaves a kept entry.
    mutating func show(_ id: ItemID) {
        selectedID = id
        selectedEntry = nil
    }

    /// The next tab, the first after the last.
    public mutating func selectNext() {
        guard let index = selectedIndex else { return }
        show(items[(index + 1) % items.count].id)
    }

    /// The previous tab, the last before the first.
    public mutating func selectPrevious() {
        guard let index = selectedIndex else { return }
        show(items[(index + items.count - 1) % items.count].id)
    }

    /// Closes a tab with all its panes and returns them. When it was the selected one, its right neighbour is selected, or the left one when it was the last.
    @discardableResult
    public mutating func close(item id: ItemID) -> [PaneID] { take(item: id)?.panes ?? [] }

    /// Takes a tab out whole, its panes still running (to be kept in the Favorites, or put in another window). The selection moves as when it is closed.
    public mutating func take(item id: ItemID) -> Item? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        let wasSelected = selectedID == id
        let item = items.remove(at: index)
        if items.isEmpty {
            selectedID = nil
        } else if wasSelected {
            selectedID = items[min(index, items.count - 1)].id
        }
        return item
    }

    /// Puts a tab that exists (released from the Favorites, or taken from another window) at `index`, brought inside, and selects it. A tab that is
    /// already here is not put twice.
    public mutating func insert(_ item: Item, at index: Int) {
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.insert(item, at: min(max(index, 0), items.count))
        show(item.id)
    }

    /// Closes every tab but one, which is selected; returns the panes that went.
    @discardableResult
    public mutating func closeOthers(than id: ItemID) -> [PaneID] {
        guard items.contains(where: { $0.id == id }) else { return [] }
        let gone = items.filter { $0.id != id }.flatMap(\.panes)
        items.removeAll { $0.id != id }
        selectedID = id
        return gone
    }

    /// Moves a tab to `index` (brought inside the list); the selection stays on the same tab.
    public mutating func move(item id: ItemID, to index: Int) {
        guard let from = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: from)
        items.insert(item, at: min(max(index, 0), items.count))
    }
}
