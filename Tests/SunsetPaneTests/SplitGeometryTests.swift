import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

@Suite("Split geometry") struct SplitGeometryTests {
    let a = PaneID(), b = PaneID(), c = PaneID()
    let bounds = CGRect(x: 10, y: 20, width: 200, height: 100)

    @Test func `one pane fills the bounds`() {
        #expect(SplitLayout.pane(a).frames(in: bounds) == [a: bounds])
    }

    @Test func `two panes side by side share the width by the ratio`() {
        let layout = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right)
        let frames = layout.frames(in: bounds)
        #expect(frames[a] == CGRect(x: 10, y: 20, width: 100, height: 100))
        #expect(frames[b] == CGRect(x: 110, y: 20, width: 100, height: 100))
    }

    @Test func `a gap between panes is taken out of the space, not added to it`() {
        let layout = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .bottom)
        let frames = layout.frames(in: bounds, gap: 10)
        #expect(frames[a] == CGRect(x: 10, y: 20, width: 200, height: 45))
        #expect(frames[b] == CGRect(x: 10, y: 75, width: 200, height: 45))
    }

    @Test func `nested splits divide the space they were given`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .bottom)
        let frames = layout.frames(in: bounds)
        #expect(frames[a] == CGRect(x: 10, y: 20, width: 100, height: 100))
        #expect(frames[b] == CGRect(x: 110, y: 20, width: 100, height: 50))
        #expect(frames[c] == CGRect(x: 110, y: 70, width: 100, height: 50))
    }

    @Test func `a divider knows its split, the gap it fills and the path to it`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .bottom)
        let dividers = layout.dividers(in: bounds, gap: 4)
        #expect(dividers.count == 2)
        let root = dividers.first { $0.path.isEmpty }
        #expect(root?.axis == .horizontal && root?.container == bounds)
        #expect(root?.gap == CGRect(x: 108, y: 20, width: 4, height: 100))
        let inner = dividers.first { $0.path == [.second] }
        #expect(inner?.axis == .vertical)
        #expect(inner?.container == CGRect(x: 112, y: 20, width: 98, height: 100))
    }

    @Test func `the ratio of a divider can be set by its path, and stays away from the ends`() {
        let layout = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right)
        #expect(
            layout.settingRatio(0.3, at: [])
                == .split(.horizontal, ratio: 0.3, first: .pane(a), second: .pane(b))
        )
        #expect(layout.settingRatio(0, at: []).ratio(at: []) == SplitLayout.minimumRatio)
        #expect(layout.settingRatio(1, at: []).ratio(at: []) == 1 - SplitLayout.minimumRatio)
        #expect(layout.settingRatio(0.3, at: [.first]) == layout, "a path that ends in a pane changes nothing")
    }

    @Test func `dragging a divider gives the ratio of the pointer inside the container, gap excluded`() {
        let layout = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right)
        let divider = layout.dividers(in: bounds, gap: 10)[0]
        // Usable width 190; the pointer at x = 10 + 95 + 5 (the middle of the gap) is half way.
        #expect(abs(divider.ratio(at: CGPoint(x: 110, y: 50)) - 0.5) < 1e-9)
        #expect(abs(divider.ratio(at: CGPoint(x: 10 + 5 + 38, y: 50)) - 0.2) < 1e-9)
        #expect(divider.ratio(at: CGPoint(x: -500, y: 0)) == SplitLayout.minimumRatio)
    }

    @Test func `the neighbour in a direction is the pane beside it that overlaps most`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .bottom)
        #expect(layout.pane(toward: .right, of: a, in: bounds) == b)
        #expect(layout.pane(toward: .left, of: c, in: bounds) == a)
        #expect(layout.pane(toward: .bottom, of: b, in: bounds) == c)
        #expect(layout.pane(toward: .top, of: c, in: bounds) == b)
        #expect(layout.pane(toward: .left, of: a, in: bounds) == nil)
        #expect(layout.pane(toward: .top, of: a, in: bounds) == nil)
    }
}
