/// Something a row of a choice list can do, with the key that does it from the list (shown on the right in the actions panel).
package struct ChoiceAction: Identifiable {
    package let id: String
    package var title: String
    package var symbol: String
    package var key: String?
    package var perform: @MainActor () -> Void

    package init(_ title: String, symbol: String, key: String? = nil, perform: @escaping @MainActor () -> Void) {
        id = title
        self.title = title
        self.symbol = symbol
        self.key = key
        self.perform = perform
    }

    /// The keys of the first three actions, by position.
    package static let positionKeys = ["\u{21A9}", "\u{2318}\u{21A9}", "\u{2325}\u{21A9}"]

    /// `actions` with the keys of their positions where they have none of their own.
    package static func keyed(_ actions: [ChoiceAction]) -> [ChoiceAction] {
        actions.enumerated()
            .map { index, action in
                var action = action
                if action.key == nil, index < positionKeys.count { action.key = positionKeys[index] }
                return action
            }
    }
}
