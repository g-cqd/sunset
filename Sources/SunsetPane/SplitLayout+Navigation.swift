public import CoreGraphics

extension SplitLayout {
    /// The pane after `id` in reading order, the first after the last; nil when `id` is not in the layout.
    public func pane(after id: PaneID) -> PaneID? {
        let all = panes
        guard let index = all.firstIndex(of: id) else { return nil }
        return all[(index + 1) % all.count]
    }

    /// The pane before `id` in reading order, the last before the first; nil when `id` is not in the layout.
    public func pane(before id: PaneID) -> PaneID? {
        let all = panes
        guard let index = all.firstIndex(of: id) else { return nil }
        return all[(index + all.count - 1) % all.count]
    }

    /// The pane next to `id` in a direction, when the layout fills `bounds`: of the panes that lie wholly on that side and share some of its extent, the one
    /// sharing most of it, then the nearer, then the first in reading order. nil when there is none.
    public func pane(toward edge: PaneEdge, of id: PaneID, in bounds: CGRect, gap: Double = 0) -> PaneID? {
        let frames = frames(in: bounds, gap: gap)
        guard let from = frames[id] else { return nil }
        let epsilon = 0.001
        var best: (id: PaneID, overlap: Double, distance: Double)?
        for other in panes where other != id {
            guard let frame = frames[other] else { continue }
            let distance: Double
            let overlap: Double
            switch edge {
                case .right:
                    distance = frame.minX - from.maxX
                    overlap = Self.overlap(from.minY, from.maxY, frame.minY, frame.maxY)
                case .left:
                    distance = from.minX - frame.maxX
                    overlap = Self.overlap(from.minY, from.maxY, frame.minY, frame.maxY)
                case .bottom:
                    distance = frame.minY - from.maxY
                    overlap = Self.overlap(from.minX, from.maxX, frame.minX, frame.maxX)
                case .top:
                    distance = from.minY - frame.maxY
                    overlap = Self.overlap(from.minX, from.maxX, frame.minX, frame.maxX)
            }
            guard distance >= -epsilon, overlap > epsilon else { continue }
            if let current = best, (overlap, -distance) <= (current.overlap, -current.distance) { continue }
            best = (other, overlap, distance)
        }
        return best?.id
    }

    private static func overlap(_ a0: Double, _ a1: Double, _ b0: Double, _ b1: Double) -> Double {
        max(0, min(a1, b1) - max(a0, b0))
    }
}
