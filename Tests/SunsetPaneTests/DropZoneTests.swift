import CoreGraphics
import Testing

@testable import SunsetPane

@Suite("Drop zone") struct DropZoneTests {
    let rect = CGRect(x: 100, y: 50, width: 400, height: 200)

    @Test func `the four triangles cut by the diagonals give the edge nearest the pointer`() {
        #expect(DropZone.edge(at: CGPoint(x: 110, y: 150), in: rect) == .left)
        #expect(DropZone.edge(at: CGPoint(x: 490, y: 150), in: rect) == .right)
        #expect(DropZone.edge(at: CGPoint(x: 300, y: 55), in: rect) == .top)
        #expect(DropZone.edge(at: CGPoint(x: 300, y: 245), in: rect) == .bottom)
    }

    @Test
    func `a corner goes to the side along which it is further from the centre, in the rectangle's own proportions`() {
        // A wide rectangle: near the top left corner, 1/10 across and 1/2 up, is still the top (2/10 of the way in height, 1/10 in width).
        #expect(DropZone.edge(at: CGPoint(x: 140, y: 60), in: rect) == .top)
        #expect(DropZone.edge(at: CGPoint(x: 120, y: 120), in: rect) == .left)
    }

    @Test func `outside the rectangle it still answers, by the same rule`() {
        #expect(DropZone.edge(at: CGPoint(x: 0, y: 150), in: rect) == .left)
        #expect(DropZone.edge(at: CGPoint(x: 900, y: 150), in: rect) == .right)
    }

    @Test func `an empty rectangle gives the right edge`() {
        #expect(DropZone.edge(at: .zero, in: .zero) == .right)
    }

    @Test func `the preview is the half of the rectangle on that side`() {
        #expect(DropZone.preview(.left, in: rect) == CGRect(x: 100, y: 50, width: 200, height: 200))
        #expect(DropZone.preview(.right, in: rect) == CGRect(x: 300, y: 50, width: 200, height: 200))
        #expect(DropZone.preview(.top, in: rect) == CGRect(x: 100, y: 50, width: 400, height: 100))
        #expect(DropZone.preview(.bottom, in: rect) == CGRect(x: 100, y: 150, width: 400, height: 100))
    }
}
