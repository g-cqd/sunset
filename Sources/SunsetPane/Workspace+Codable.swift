import Foundation

/// `{"items": [{"id", "layout", "focused", "customTitle"?, "customIcon"?}], "selected": "<id>"}`. Reading checks what the rest of the code relies on: a pane is
/// in one tab only, a tab's
/// focused pane is one of its panes, and the selected tab exists (and is the first one when none is named).
extension Workspace: Codable {
    private enum Key: String, CodingKey { case items, selected }
    private struct Stored: Codable {
        let id: ItemID
        let layout: SplitLayout
        let focused: PaneID
        var customTitle: String?
        var customIcon: PaneIcon?
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let stored = try container.decode([Stored].self, forKey: .items)
        var seen = Set<PaneID>()
        var ids = Set<ItemID>()
        for item in stored {
            let panes = item.layout.panes
            guard panes.contains(item.focused), seen.isDisjoint(with: panes), Set(panes).count == panes.count,
                ids.insert(item.id).inserted
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .items,
                    in: container,
                    debugDescription: "a tab that does not hold together"
                )
            }
            seen.formUnion(panes)
        }
        let selected = try container.decodeIfPresent(ItemID.self, forKey: .selected)
        if let selected, !ids.contains(selected) {
            throw DecodingError.dataCorruptedError(
                forKey: .selected,
                in: container,
                debugDescription: "a selected tab that is not there"
            )
        }
        self.init()
        items = stored.map {
            Item(
                id: $0.id,
                layout: $0.layout,
                focused: $0.focused,
                customTitle: $0.customTitle,
                customIcon: $0.customIcon
            )
        }
        selectedID = selected ?? items.first?.id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(
            items.map {
                Stored(
                    id: $0.id,
                    layout: $0.layout,
                    focused: $0.focused,
                    customTitle: $0.customTitle,
                    customIcon: $0.customIcon
                )
            },
            forKey: .items
        )
        try container.encodeIfPresent(selectedID, forKey: .selected)
    }
}
