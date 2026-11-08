import CoreGraphics
import Foundation
import Testing

@testable import SunsetPane

@Suite("Drop target") struct DropTargetTests {
    let a = PaneID(), b = PaneID()
    var frames: [PaneID: CGRect] {
        [a: CGRect(x: 0, y: 0, width: 100, height: 100), b: CGRect(x: 102, y: 0, width: 98, height: 100)]
    }

    @Test func `the pane under the pointer is the target, with the edge nearest the pointer inside it`() {
        #expect(DropZone.target(at: CGPoint(x: 10, y: 50), among: frames)?.pane == a)
        #expect(DropZone.target(at: CGPoint(x: 10, y: 50), among: frames)?.edge == .left)
        #expect(DropZone.target(at: CGPoint(x: 190, y: 50), among: frames)?.pane == b)
        #expect(DropZone.target(at: CGPoint(x: 190, y: 50), among: frames)?.edge == .right)
        #expect(DropZone.target(at: CGPoint(x: 150, y: 95), among: frames)?.edge == .bottom)
    }

    @Test func `a pointer in the gap, or outside, goes to the nearest pane`() {
        #expect(
            DropZone.target(at: CGPoint(x: 101, y: 50), among: frames)?.pane == a
                || DropZone.target(at: CGPoint(x: 101, y: 50), among: frames)?.pane == b
        )
        #expect(DropZone.target(at: CGPoint(x: -50, y: 50), among: frames)?.pane == a)
        #expect(DropZone.target(at: CGPoint(x: 400, y: 50), among: frames)?.pane == b)
    }

    @Test func `with no panes there is no target`() {
        #expect(DropZone.target(at: .zero, among: [:]) == nil)
    }

    @Test func `the preview of a target is the half of its pane`() throws {
        let target = try #require(DropZone.target(at: CGPoint(x: 10, y: 50), among: frames))
        #expect(target.preview == CGRect(x: 0, y: 0, width: 50, height: 100))
    }
}
