import Testing

@testable import SunsetPane

@Suite("Pane edge") struct PaneEdgeTests {
    @Test func `an edge's opposite is the other side of the same axis`() {
        #expect(PaneEdge.left.opposite == .right && PaneEdge.right.opposite == .left)
        #expect(PaneEdge.top.opposite == .bottom && PaneEdge.bottom.opposite == .top)
        for edge in PaneEdge.allCases { #expect(edge.opposite.opposite == edge && edge.opposite.axis == edge.axis) }
    }
}
