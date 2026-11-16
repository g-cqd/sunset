extension SplitLayout {
    /// The same layout with other panes: each pane that `panes` names is the one it names.
    func replacing(_ panes: [PaneID: PaneID]) -> SplitLayout {
        switch self {
            case .pane(let pane): .pane(panes[pane] ?? pane)
            case .split(let axis, let ratio, let first, let second):
                .split(axis, ratio: ratio, first: first.replacing(panes), second: second.replacing(panes))
        }
    }
}
