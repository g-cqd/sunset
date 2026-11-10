/// How the border stroke of a terminal pane's card is drawn: none when the terminal fills the window without a card, the subtle hairline on an ordinary card,
/// a brighter hover hairline when the pointer is over that pane's sub-tab in the split container, or the system accent stroke on the focused pane of a split.
public enum PaneStrokeStyle: Sendable, Equatable {
    case none
    case hairline
    case hovered
    case focused

    public static func of(
        pane: PaneID,
        isCard: Bool,
        isSplit: Bool,
        focused: PaneID,
        hovered: PaneID?
    ) -> PaneStrokeStyle {
        guard isCard else { return .none }
        guard isSplit else { return .hairline }
        if pane == focused { return .focused }
        if pane == hovered { return .hovered }
        return .hairline
    }
}
