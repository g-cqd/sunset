extension SplitLayout {
    /// The layout with `block` (one pane or a whole layout) placed on `edge` of the pane `target`, taking `ratio` of that pane's space. A pane of `block`
    /// that is already in the layout is moved. A target that is not in the layout leaves the layout as it is.
    public func inserting(_ block: SplitLayout, beside target: PaneID, edge: PaneEdge, ratio: Double = 0.5)
        -> SplitLayout
    {
        guard contains(target), !block.panes.contains(target) else { return self }
        var base = self
        for moved in block.panes where base.contains(moved) {
            guard let rest = base.removing(moved) else { return self }
            base = rest
        }
        return base.attaching(block, to: target, edge: edge, share: min(max(ratio, 0), 1))
    }

    /// The layout without `id`, whose space goes to its sibling; nil when it was the only pane. A pane that is not there changes nothing.
    public func removing(_ id: PaneID) -> SplitLayout? {
        switch self {
            case .pane(let own):
                return own == id ? nil : self
            case .split(let axis, let ratio, let first, let second):
                guard contains(id) else { return self }
                guard let kept = first.removing(id) else { return second }
                guard let other = second.removing(id) else { return kept }
                return .split(axis, ratio: ratio, first: kept, second: other)
        }
    }

    /// The share of the first part of the split at `path`; nil when `path` does not end at a split.
    public func ratio(at path: [SplitBranch]) -> Double? {
        switch (self, path.first) {
            case (.split(_, let ratio, _, _), nil): ratio
            case (.split(_, _, let first, _), .first): first.ratio(at: Array(path.dropFirst()))
            case (.split(_, _, _, let second), .second): second.ratio(at: Array(path.dropFirst()))
            default: nil
        }
    }

    /// The layout with the split at `path` divided in `ratio`, kept `minimumRatio` away from either end. A path that does not end at a split changes nothing.
    public func settingRatio(_ ratio: Double, at path: [SplitBranch]) -> SplitLayout {
        guard case .split(let axis, let old, let first, let second) = self else { return self }
        switch path.first {
            case nil:
                let kept = min(max(ratio, Self.minimumRatio), 1 - Self.minimumRatio)
                return .split(axis, ratio: kept, first: first, second: second)
            case .first:
                return .split(
                    axis,
                    ratio: old,
                    first: first.settingRatio(ratio, at: Array(path.dropFirst())),
                    second: second
                )
            case .second:
                return .split(
                    axis,
                    ratio: old,
                    first: first,
                    second: second.settingRatio(ratio, at: Array(path.dropFirst()))
                )
        }
    }

    private func attaching(_ block: SplitLayout, to target: PaneID, edge: PaneEdge, share: Double) -> SplitLayout {
        switch self {
            case .pane(let own):
                guard own == target else { return self }
                return edge.placesFirst
                    ? .split(edge.axis, ratio: share, first: block, second: self)
                    : .split(edge.axis, ratio: 1 - share, first: self, second: block)
            case .split(let axis, let ratio, let first, let second):
                if first.contains(target) {
                    return .split(
                        axis,
                        ratio: ratio,
                        first: first.attaching(block, to: target, edge: edge, share: share),
                        second: second
                    )
                }
                return .split(
                    axis,
                    ratio: ratio,
                    first: first,
                    second: second.attaching(block, to: target, edge: edge, share: share)
                )
        }
    }
}
