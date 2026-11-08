import Foundation
import Testing

@testable import SunsetPane

@Suite("Split layout") struct SplitLayoutTests {
    let a = PaneID(), b = PaneID(), c = PaneID(), d = PaneID()

    @Test func `a single pane is its own layout`() {
        let layout = SplitLayout.pane(a)
        #expect(layout.panes == [a] && layout.contains(a) && !layout.contains(b))
    }

    @Test(arguments: [PaneEdge.left, .right, .top, .bottom])
    func `a pane dropped on an edge goes on that side, taking half`(edge: PaneEdge) {
        let layout = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: edge)
        let expectedAxis: SplitAxis = (edge == .left || edge == .right) ? .horizontal : .vertical
        let newIsFirst = edge == .left || edge == .top
        let expected = SplitLayout.split(
            expectedAxis,
            ratio: 0.5,
            first: .pane(newIsFirst ? b : a),
            second: .pane(newIsFirst ? a : b)
        )
        #expect(layout == expected)
        #expect(layout.panes == (newIsFirst ? [b, a] : [a, b]))
    }

    @Test func `the share of the new pane can be chosen, whichever side it goes`() {
        let right = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right, ratio: 0.25)
        #expect(right == .split(.horizontal, ratio: 0.75, first: .pane(a), second: .pane(b)))
        let left = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .left, ratio: 0.25)
        #expect(left == .split(.horizontal, ratio: 0.25, first: .pane(b), second: .pane(a)))
    }

    @Test func `inserting beside one pane of a split splits only that pane`() {
        let two = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right)
        let three = two.inserting(.pane(c), beside: b, edge: .bottom)
        #expect(
            three
                == .split(
                    .horizontal,
                    ratio: 0.5,
                    first: .pane(a),
                    second: .split(.vertical, ratio: 0.5, first: .pane(b), second: .pane(c))
                )
        )
        #expect(three.panes == [a, b, c])
    }

    @Test func `a whole layout can be inserted as one block`() {
        let pair = SplitLayout.pane(b).inserting(.pane(c), beside: b, edge: .right)
        let layout = SplitLayout.pane(a).inserting(pair, beside: a, edge: .left)
        #expect(layout.panes == [b, c, a])
    }

    @Test func `inserting beside a pane that is not there changes nothing`() {
        let layout = SplitLayout.pane(a)
        #expect(layout.inserting(.pane(b), beside: c, edge: .left) == layout)
    }

    @Test func `inserting a pane that is already in the layout moves it`() {
        let two = SplitLayout.pane(a).inserting(.pane(b), beside: a, edge: .right)
        let moved = two.inserting(.pane(a), beside: b, edge: .right)
        #expect(moved.panes == [b, a])
    }

    @Test func `removing a pane gives its space to its sibling`() {
        let three = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .bottom)
        #expect(
            three.removing(c) == .split(.horizontal, ratio: 0.5, first: .pane(a), second: .pane(b))
        )
        #expect(three.removing(a) == .split(.vertical, ratio: 0.5, first: .pane(b), second: .pane(c)))
    }

    @Test func `removing the only pane leaves nothing, and a pane that is not there leaves it as it is`() {
        #expect(SplitLayout.pane(a).removing(a) == nil)
        #expect(SplitLayout.pane(a).removing(b) == .pane(a))
    }

    @Test func `the next and previous pane go round`() {
        let layout = SplitLayout.pane(a)
            .inserting(.pane(b), beside: a, edge: .right)
            .inserting(.pane(c), beside: b, edge: .right)
        #expect(layout.pane(after: a) == b && layout.pane(after: c) == a)
        #expect(layout.pane(before: a) == c && layout.pane(before: b) == a)
        #expect(SplitLayout.pane(a).pane(after: a) == a)
        #expect(layout.pane(after: d) == nil)
    }
}
