public import CoreGraphics
public import Foundation

/// How the panes of one tab are arranged: a binary tree whose leaves are panes and whose nodes split their space in two along an axis. A split has a
/// `ratio`, the share of the first part (left or top). Positions use a top-left origin, like the views that draw them.
///
/// It is a value; every edit returns a new layout. A layout is never empty: removing its last pane gives `nil`.
public indirect enum SplitLayout: Sendable, Equatable {
    case pane(PaneID)
    case split(SplitAxis, ratio: Double, first: SplitLayout, second: SplitLayout)

    /// The smallest share either part of a split keeps (a divider cannot be dragged past it).
    public static let minimumRatio = 0.1

    /// The panes, left to right and top to bottom.
    public var panes: [PaneID] {
        switch self {
            case .pane(let id): [id]
            case .split(_, _, let first, let second): first.panes + second.panes
        }
    }

    public func contains(_ id: PaneID) -> Bool {
        switch self {
            case .pane(let own): own == id
            case .split(_, _, let first, let second): first.contains(id) || second.contains(id)
        }
    }

    /// The rectangle of every pane when the layout fills `bounds`, with `gap` points between the two parts of every split (taken out of the space).
    public func frames(in bounds: CGRect, gap: Double = 0) -> [PaneID: CGRect] {
        var result: [PaneID: CGRect] = [:]
        place(in: bounds, gap: gap) { result[$0] = $1 }
        return result
    }

    /// The dividers of every split, outermost first.
    public func dividers(in bounds: CGRect, gap: Double = 0) -> [SplitDivider] {
        var result: [SplitDivider] = []
        divide(in: bounds, gap: gap, path: []) { result.append($0) }
        return result
    }

    // MARK: Layout

    private func place(in bounds: CGRect, gap: Double, _ emit: (PaneID, CGRect) -> Void) {
        switch self {
            case .pane(let id):
                emit(id, bounds)
            case .split(let axis, let ratio, let first, let second):
                let parts = Self.parts(of: bounds, axis: axis, ratio: ratio, gap: gap)
                first.place(in: parts.first, gap: gap, emit)
                second.place(in: parts.second, gap: gap, emit)
        }
    }

    private func divide(in bounds: CGRect, gap: Double, path: [SplitBranch], _ emit: (SplitDivider) -> Void) {
        guard case .split(let axis, let ratio, let first, let second) = self else { return }
        let parts = Self.parts(of: bounds, axis: axis, ratio: ratio, gap: gap)
        emit(SplitDivider(path: path, axis: axis, container: bounds, gap: parts.gap, gapSize: gap))
        first.divide(in: parts.first, gap: gap, path: path + [.first], emit)
        second.divide(in: parts.second, gap: gap, path: path + [.second], emit)
    }

    private static func parts(of bounds: CGRect, axis: SplitAxis, ratio: Double, gap: Double)
        -> (first: CGRect, gap: CGRect, second: CGRect)
    {
        switch axis {
            case .horizontal:
                let width = (bounds.width - gap) * ratio
                let first = CGRect(x: bounds.minX, y: bounds.minY, width: width, height: bounds.height)
                let space = CGRect(x: first.maxX, y: bounds.minY, width: gap, height: bounds.height)
                let second = CGRect(
                    x: space.maxX,
                    y: bounds.minY,
                    width: bounds.maxX - space.maxX,
                    height: bounds.height
                )
                return (first, space, second)
            case .vertical:
                let height = (bounds.height - gap) * ratio
                let first = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: height)
                let space = CGRect(x: bounds.minX, y: first.maxY, width: bounds.width, height: gap)
                let second = CGRect(
                    x: bounds.minX,
                    y: space.maxY,
                    width: bounds.width,
                    height: bounds.maxY - space.maxY
                )
                return (first, space, second)
        }
    }
}
