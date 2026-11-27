import AppKit
import SunsetTestSupport
import Testing

@testable import SunsetShell

/// A Now Playing card's title scrolls only when it is longer than its room, by a Core Animation animation (the render
/// server's, no frame computed in the app); a layout that changes nothing keeps the same animation going.
@MainActor @Suite("A title that scrolls", .macOS27)
struct MarqueeTextTests {
    private func view(width: CGFloat, text: String) -> MarqueeTextView {
        let view = MarqueeTextView(frame: NSRect(x: 0, y: 0, width: width, height: 16))
        view.text = text
        view.layoutSubtreeIfNeeded()
        view.layout()
        return view
    }

    private func animation(_ view: MarqueeTextView) -> CAAnimation? {
        view.layer?.sublayers?.first?.animation(forKey: "marquee")
    }

    @Test func `a title that fits stays still; one that does not scrolls, faded at its edges`() throws {
        let short = view(width: 400, text: "Song")
        #expect(animation(short) == nil && short.layer?.mask == nil)
        let long = view(width: 60, text: "A song whose title is far longer than its card")
        let scrolling = try #require(animation(long) as? CAKeyframeAnimation)
        #expect(scrolling.repeatCount == .infinity && scrolling.keyPath == "transform.translation.x")
        #expect(long.layer?.mask != nil)
    }

    @Test func `a layout that changes nothing keeps the animation; new text makes a new one`() throws {
        let long = view(width: 60, text: "A song whose title is far longer than its card")
        let before = try #require(animation(long))
        long.layout()
        #expect(animation(long) === before)
        long.text = "Another song whose title is far longer than its card"
        #expect(animation(long) !== before)
        long.text = "Fits"
        #expect(animation(long) == nil)
    }
}
