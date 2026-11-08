import Testing

@testable import SunsetHost

@Suite("Hover reveal") struct HoverRevealTests {
    private let start = ContinuousClock.now

    @Test func `it is hidden until the pointer is on the strip, then shown at once`() {
        var reveal = HoverReveal(hideDelay: .milliseconds(300))
        #expect(!reveal.isShown(at: start))
        reveal.pointer(inside: true, at: start)
        #expect(reveal.isShown(at: start))
    }

    @Test func `after the pointer leaves it stays for the delay, then hides`() {
        var reveal = HoverReveal(hideDelay: .milliseconds(300))
        reveal.pointer(inside: true, at: start)
        reveal.pointer(inside: false, at: start + .milliseconds(100))
        #expect(reveal.isShown(at: start + .milliseconds(350)), "250 ms after leaving")
        #expect(!reveal.isShown(at: start + .milliseconds(450)), "350 ms after leaving")
        #expect(reveal.hidesAt == start + .milliseconds(400))
    }

    @Test func `coming back inside the delay keeps it shown`() {
        var reveal = HoverReveal(hideDelay: .milliseconds(300))
        reveal.pointer(inside: true, at: start)
        reveal.pointer(inside: false, at: start + .milliseconds(100))
        reveal.pointer(inside: true, at: start + .milliseconds(250))
        #expect(reveal.isShown(at: start + .seconds(5)))
        #expect(reveal.hidesAt == nil)
    }

    @Test func `with no delay it hides when the pointer leaves`() {
        var reveal = HoverReveal(hideDelay: .zero)
        reveal.pointer(inside: true, at: start)
        reveal.pointer(inside: false, at: start + .seconds(1))
        #expect(!reveal.isShown(at: start + .seconds(1)))
    }
}
