import AppKit

/// The view of `PointerShieldView`: every click, scroll and right click lands on it, the pointer is the arrow over it, and its
/// window is shielded while it is in one.
final class PointerShieldNSView: NSView {
    var onClick: () -> Void = {}
    private weak var shieldedWindow: NSWindow?

    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { onClick() }
    override func rightMouseDown(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}
    override func resetCursorRects() { addCursorRect(bounds, cursor: .arrow) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let shieldedWindow, shieldedWindow !== window { PointerShield.set(false, for: shieldedWindow) }
        shieldedWindow = window
        if let window { PointerShield.set(true, for: window) }
    }

    isolated deinit {
        if let shieldedWindow { PointerShield.set(false, for: shieldedWindow) }
    }
}
