import AppKit
import QuartzCore

/// One line of text that scrolls when it is longer than its room, as Music's Now Playing does: it waits, then scrolls by
/// one length and a gap to where it began, and again. The scroll is a Core Animation animation, run by the render server:
/// no frame of it is computed in the app, and a window that is not shown costs nothing. A line that fits, and any line
/// while Reduce Motion is on, stays still, cut with an ellipsis.
final class MarqueeTextView: NSView {
    var text = "" {
        didSet {
            if text != oldValue { refresh() }
        }
    }
    var font = NSFont.preferredFont(forTextStyle: .body) {
        didSet {
            if font != oldValue { refresh() }
        }
    }
    var color = NSColor.labelColor {
        didSet {
            refresh()
        }
    }

    /// Points a second, and the pause at the start of each turn.
    static let speed = 30.0
    static let pause = 2.0
    /// The space between the end of the text and its next start.
    static let gap = 32.0
    /// How far the edges fade.
    static let fade = 10.0

    private let strip = CALayer()
    private let first = CATextLayer()
    private let second = CATextLayer()
    private let edges = CAGradientLayer()
    private var shownFor: (String, CGFloat)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.addSublayer(strip)
        for label in [first, second] {
            label.truncationMode = .end
            label.isWrapped = false
            strip.addSublayer(label)
        }
        edges.startPoint = CGPoint(x: 0, y: 0.5)
        edges.endPoint = CGPoint(x: 1, y: 0.5)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: ceil(font.ascender - font.descender + font.leading))
    }

    override func layout() {
        super.layout()
        refresh()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        refresh()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refresh()
    }

    private func refresh() {
        let width = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        let room = bounds.width
        let scrolls = width > room && room > 0 && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let scale = window?.backingScaleFactor ?? 2
        var cg = color.cgColor
        effectiveAppearance.performAsCurrentDrawingAppearance { cg = color.cgColor }
        for label in [first, second] {
            label.string = text
            label.font = font
            label.fontSize = font.pointSize
            label.foregroundColor = cg
            label.contentsScale = scale
        }
        let height = bounds.height
        first.frame = CGRect(x: 0, y: 0, width: scrolls ? width : room, height: height)
        second.frame = CGRect(x: width + Self.gap, y: 0, width: width, height: height)
        second.isHidden = !scrolls
        strip.frame = CGRect(x: 0, y: 0, width: width * 2 + Self.gap, height: height)
        layer?.mask = scrolls ? edgesMask() : nil
        CATransaction.commit()
        // The animation is made again only when what it scrolls changed: a layout that changes nothing keeps it going.
        let wanted: (String, CGFloat)? = scrolls ? (text, width) : nil
        guard wanted?.0 != shownFor?.0 || wanted?.1 != shownFor?.1 else { return }
        shownFor = wanted
        strip.removeAllAnimations()
        edges.removeAllAnimations()
        guard scrolls else { return }
        // Both in one transaction: they start together, and keep in step.
        CATransaction.begin()
        strip.add(Self.scrolling(by: width + Self.gap), forKey: "marquee")
        edges.add(Self.leadingFade(scrolling: width + Self.gap), forKey: "marquee")
        CATransaction.commit()
    }

    /// The leading edge fades only while the text is away from its start (n132: it faded the first letters at rest): none
    /// during the pause, in as the text leaves, out as its next copy comes back to the start, in step with `scrolling`.
    private static func leadingFade(scrolling distance: CGFloat) -> CAAnimation {
        let total = pause + Double(distance) / speed
        let turn = min(fade / speed, total / 4) / total
        let start = pause / total
        let solid = NSColor.black.cgColor
        let clear = NSColor.clear.cgColor
        let still = [solid, solid, solid, clear]
        let moving = [clear, solid, solid, clear]
        let animation = CAKeyframeAnimation(keyPath: "colors")
        animation.values = [still, still, moving, moving, still]
        animation.keyTimes = [0, start, start + turn, 1 - turn, 1].map { NSNumber(value: $0) }
        animation.duration = total
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        return animation
    }

    private func edgesMask() -> CALayer {
        edges.frame = bounds
        let clear = NSColor.clear.cgColor
        let solid = NSColor.black.cgColor
        let edge = NSNumber(value: Double(min(Self.fade / max(bounds.width, 1), 0.25)))
        // At rest the leading edge does not fade (n132); while the text scrolls, `leadingFade` fades it.
        edges.colors = [solid, solid, solid, clear]
        edges.locations = [0, edge, NSNumber(value: 1 - edge.doubleValue), 1]
        return edges
    }

    /// Waits, then moves `distance` to the left at `speed`, and starts again from where it began (where the second copy
    /// stands then, so the jump does not show).
    private static func scrolling(by distance: CGFloat) -> CAAnimation {
        let travel = Double(distance) / speed
        let total = pause + travel
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, 0, -distance]
        animation.keyTimes = [0, NSNumber(value: pause / total), 1]
        animation.duration = total
        animation.repeatCount = .infinity
        animation.calculationMode = .linear
        animation.isRemovedOnCompletion = false
        return animation
    }
}
