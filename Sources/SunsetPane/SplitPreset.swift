/// How a split tab can be laid out at once (n78, t287): the fourth light's presets, as the green light's are for windows.
public enum SplitPreset: String, CaseIterable, Sendable {
    case sideBySide, stacked, threeColumns, largeAndTwoStacked, grid

    /// How many panes it lays out.
    public var paneCount: Int {
        switch self {
            case .sideBySide, .stacked: 2
            case .threeColumns, .largeAndTwoStacked: 3
            case .grid: 4
        }
    }

    /// Its name in the panel.
    public var title: String {
        switch self {
            case .sideBySide: "Side by Side"
            case .stacked: "Stacked"
            case .threeColumns: "Three Columns"
            case .largeAndTwoStacked: "One Large, Two Stacked"
            case .grid: "Grid"
        }
    }

    /// The first `paneCount` of `panes` in its shape, left to right and top to bottom.
    /// - Parameter panes: At least `paneCount` panes.
    /// - Returns: The layout.
    public func layout(of panes: [PaneID]) -> SplitLayout {
        let p = panes.map(SplitLayout.pane)
        switch self {
            case .sideBySide: return .split(.horizontal, ratio: 0.5, first: p[0], second: p[1])
            case .stacked: return .split(.vertical, ratio: 0.5, first: p[0], second: p[1])
            case .threeColumns:
                return .split(
                    .horizontal,
                    ratio: 1.0 / 3,
                    first: p[0],
                    second: .split(.horizontal, ratio: 0.5, first: p[1], second: p[2])
                )
            case .largeAndTwoStacked:
                return .split(
                    .horizontal,
                    ratio: 0.5,
                    first: p[0],
                    second: .split(.vertical, ratio: 0.5, first: p[1], second: p[2])
                )
            case .grid:
                return .split(
                    .vertical,
                    ratio: 0.5,
                    first: .split(.horizontal, ratio: 0.5, first: p[0], second: p[1]),
                    second: .split(.horizontal, ratio: 0.5, first: p[2], second: p[3])
                )
        }
    }
}
