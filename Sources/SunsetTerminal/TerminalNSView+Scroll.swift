package import AppKit
import SunsetConfig
import SunsetCore

/// Scrolling with the wheel and the trackpad.
///
/// A trackpad (or a Magic Mouse) sends `hasPreciseScrollingDeltas` events in points, and after a flick the system sends its own stream of momentum events
/// (`momentumPhase`), which stops when a finger touches down again: they only need turning into lines (`ScrollAccumulator`). A wheel sends whole notches
/// and no momentum, so the inertia is ours: `ScrollMomentum` turns a notch into a decaying speed, stepped once per frame by a display link that runs only
/// while the text glides.
extension TerminalNSView {
    package override func scrollWheel(with event: NSEvent) {
        if event.hasPreciseScrollingDeltas {
            stopGliding()
            let lines = scroll.lines(
                delta: event.scrollingDeltaY,
                precise: true,
                cellHeight: model.cellHeightInPoints,
                trackpad: model.scroll.trackpad,
                wheel: model.scroll.wheel
            )
            emitWheel(lines, event)
            return
        }
        guard event.scrollingDeltaY.isFinite else { return }
        momentum.timeConstant = model.scroll.inertia
        momentum.push(lines: event.scrollingDeltaY * model.scroll.wheel)
        momentumEvent = event
        emitWheel(momentum.take(), event)
        if momentum.isMoving { startGliding() }
    }

    /// Whatever glides stops: a key was pressed, or a finger is on the trackpad.
    package func stopGliding() {
        momentum.stop()
        momentumLink?.invalidate()
        momentumLink = nil
        momentumEvent = nil
    }

    private func startGliding() {
        guard momentumLink == nil else { return }
        let link = displayLink(target: self, selector: #selector(glide(_:)))
        link.add(to: .main, forMode: .common)
        momentumLink = link
    }

    @objc private func glide(_ link: CADisplayLink) {
        let lines = momentum.advance(by: link.targetTimestamp - link.timestamp)
        if let momentumEvent { emitWheel(lines, momentumEvent) }
        if !momentum.isMoving { stopGliding() }
    }

    private func emitWheel(_ lines: Int, _ event: NSEvent) {
        for _ in 0 ..< abs(lines) {
            report(.press, lines > 0 ? .wheelUp : .wheelDown, event)
        }
    }
}
