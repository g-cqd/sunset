import Testing

@testable import SunsetShell

/// Roadmap 0055: the floating bar comes out at the edge and goes after.
@Suite("A bar at the window's edge") struct EdgeRevealTests {
    @Test func `kept shown, it is always out`() {
        #expect(EdgeReveal(hides: false).isOut)
    }

    @Test func `hidden until the edge is reached, gone a moment after the pointer leaves it`() {
        var bar = EdgeReveal(hides: true)
        #expect(!bar.isOut)
        bar.reachedEdge()
        #expect(bar.isOut)
        bar.pointer(over: true)
        bar.pointer(over: false)
        #expect(bar.isOut, "a moment first")
        bar.settle()
        #expect(!bar.isOut)
    }

    @Test func `typed in, or the pointer back over it, it stays`() {
        var bar = EdgeReveal(hides: true)
        bar.reachedEdge()
        bar.typing = true
        bar.pointer(over: false)
        bar.settle()
        #expect(bar.isOut)
        bar.typing = false
        bar.pointer(over: true)
        bar.settle()
        #expect(bar.isOut)
        bar.pointer(over: false)
        bar.settle()
        #expect(!bar.isOut)
    }
}
