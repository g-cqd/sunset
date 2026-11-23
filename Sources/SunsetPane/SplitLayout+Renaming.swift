public import Foundation

extension SplitLayout {
    /// The same layout with its panes named by `names` (a pane it does not name keeps its own).
    public func renaming(_ names: [PaneID: PaneID]) -> SplitLayout {
        switch self {
            case .pane(let id):
                .pane(names[id] ?? id)
            case .split(let axis, let ratio, let first, let second):
                .split(axis, ratio: ratio, first: first.renaming(names), second: second.renaming(names))
        }
    }
}
