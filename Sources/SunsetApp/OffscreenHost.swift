import AppKit

/// A window off screen that holds a shared page while its tab is not shown: a view out of every window draws nothing.
@MainActor final class OffscreenHost {
    static let shared = OffscreenHost()
    private lazy var window: NSWindow = {
        let window = NSWindow(
            contentRect: CGRect(x: -20_000, y: -20_000, width: 1920, height: 1080),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.orderBack(nil)
        return window
    }()

    /// Holds `view` at its own size, until a tab shows it (which takes it into its window).
    func hold(_ view: NSView) {
        let size = view.frame.size.width > 0 ? view.frame.size : CGSize(width: 1280, height: 800)
        view.frame = CGRect(origin: .zero, size: size)
        window.contentView?.addSubview(view)
    }
}
