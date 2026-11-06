import AppKit
import SunsetCore

extension TerminalNSView {
    override func mouseDown(with event: NSEvent) { report(.press, .left, event) }
    override func mouseUp(with event: NSEvent) { report(.release, .left, event) }
    override func mouseDragged(with event: NSEvent) { report(.motion, .left, event) }
    override func rightMouseDown(with event: NSEvent) { report(.press, .right, event) }
    override func rightMouseUp(with event: NSEvent) { report(.release, .right, event) }
    override func rightMouseDragged(with event: NSEvent) { report(.motion, .right, event) }

    override func otherMouseDown(with event: NSEvent) { report(.press, .middle, event) }
    override func otherMouseUp(with event: NSEvent) { report(.release, .middle, event) }
    override func otherMouseDragged(with event: NSEvent) { report(.motion, .middle, event) }

    override func mouseMoved(with event: NSEvent) { report(.motion, .none, event) }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    /// One wheel event per line scrolled: a trackpad sends points, a wheel sends lines; the part of a line not yet scrolled is kept for the next event.
    override func scrollWheel(with event: NSEvent) {
        let lineHeight = event.hasPreciseScrollingDeltas ? model.cellHeightInPoints : 1
        scrollRemainder += event.scrollingDeltaY / lineHeight
        let lines = Int(scrollRemainder)
        scrollRemainder -= Double(lines)
        for _ in 0 ..< abs(lines) {
            report(.press, lines > 0 ? .wheelUp : .wheelDown, event)
        }
    }

    private func report(_ action: MouseEvent.Action, _ button: MouseEvent.Button, _ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let scale = window?.backingScaleFactor ?? 2
        model.pointer(
            action,
            button,
            pixelX: Int((point.x * scale).rounded(.down)),
            pixelY: Int((point.y * scale).rounded(.down)),
            modifiers: KeyboardMapping.modifiers(event.modifierFlags),
            clickCount: event.clickCount
        )
    }
}
