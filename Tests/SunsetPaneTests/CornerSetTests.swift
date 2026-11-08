import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

@Suite("Corners at the window") struct CornerSetTests {
    let a = PaneID(), b = PaneID(), c = PaneID()
    let bounds = CGRect(x: 10, y: 20, width: 200, height: 100)

    @Test func `a pane that fills the area is at all four corners`() {
        #expect(CornerSet.atCorners(of: bounds, in: bounds) == .all)
    }

    @Test func `the left pane of a side by side split is at the left corners only`() {
        let frames = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right).frames(in: bounds, gap: 4)
        #expect(CornerSet.atCorners(of: frames[a] ?? .zero, in: bounds) == [.topLeading, .bottomLeading])
        #expect(CornerSet.atCorners(of: frames[b] ?? .zero, in: bounds) == [.topTrailing, .bottomTrailing])
    }

    @Test func `a pane in the middle of a column has no corner at the window`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .bottom)
            .inserting(.pane(c), beside: a, edge: .bottom)
        let frames = layout.frames(in: bounds, gap: 4)
        #expect(CornerSet.atCorners(of: frames[c] ?? .zero, in: bounds) == .empty)
        #expect(CornerSet.atCorners(of: frames[a] ?? .zero, in: bounds) == [.topLeading, .topTrailing])
        #expect(CornerSet.atCorners(of: frames[b] ?? .zero, in: bounds) == [.bottomLeading, .bottomTrailing])
    }

    @Test func `a pane that touches an edge but not a corner has none there`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .bottom)
        let frames = layout.frames(in: bounds, gap: 4)
        #expect(CornerSet.atCorners(of: frames[b] ?? .zero, in: bounds) == [.topTrailing])
        #expect(CornerSet.atCorners(of: frames[c] ?? .zero, in: bounds) == [.bottomTrailing])
    }
}
