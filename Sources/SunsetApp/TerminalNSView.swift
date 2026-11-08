import AppKit
import IOSurface
import SunsetCore
import SunsetRender

/// The AppKit side of a terminal: a layer-backed view that shows the frames the model hands it, takes the keyboard, and tells the model its size in device
/// pixels. SwiftUI hosts it (`TerminalRepresentable`); AppKit is used here because a terminal needs the raw key events, the text input system and a display
/// link, none of which SwiftUI offers.
final class TerminalNSView: NSView {
    let model: TerminalModel
    var optionAsMeta = false
    private var displayLink: CADisplayLink?
    var markedText = NSAttributedString()
    var trackingArea: NSTrackingArea?
    var scroll = ScrollAccumulator()
    var momentum = ScrollMomentum(timeConstant: 0)
    var momentumLink: CADisplayLink?
    var momentumEvent: NSEvent?
    private var windowObservers: [any NSObjectProtocol] = []

    init(model: TerminalModel) {
        self.model = model
        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        // The view is flipped (row 0 at the top), and in a flipped layer-backed view the layer's gravity is flipped with it: `.topLeft` put the picture at
        // the *bottom*, so it sat lower than the grid the pointer is mapped on by the pixels left over after the last whole row (up to a cell: a click
        // selected the row below). Measured: first lit row at 34 pt with `.topLeft`, 24 pt with `.bottomLeft`, where the grid starts at 20 pt.
        layer?.contentsGravity = .bottomLeft
        layer?.isOpaque = true
        model.presentFrame = { [weak self] surface in self?.show(surface) }
        model.setDisplayLinkPaused = { [weak self] paused in self?.displayLink?.isPaused = paused }
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    // MARK: Display

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopGliding()
        displayLink?.invalidate()
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
        guard let window else { return }
        window.makeFirstResponder(self)
        let names: [Notification.Name] = [
            NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification,
            NSWindow.didChangeOcclusionStateNotification,
            NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification
        ]
        for name in names {
            windowObservers.append(
                NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.reportWindowState() }
                }
            )
        }
        reportWindowState()
        let link = displayLink(target: self, selector: #selector(displayLinkFired))
        link.isPaused = true
        link.add(to: .main, forMode: .common)
        displayLink = link
        reportSize()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        layer?.contentsScale = window?.backingScaleFactor ?? 2
        reportSize()
    }

    override func layout() {
        super.layout()
        reportSize()
    }

    private func reportWindowState() {
        guard let window else { return }
        let visible = window.occlusionState.contains(.visible) && !window.isMiniaturized
        model.windowStateChanged(focused: window.isKeyWindow, visible: visible)
    }

    @objc private func displayLinkFired() { model.tick() }

    private func reportSize() {
        let scale = window?.backingScaleFactor ?? 2
        model.viewResized(
            pixelWidth: Int(bounds.width * scale),
            pixelHeight: Int(bounds.height * scale),
            scale: Double(scale)
        )
    }

    private func show(_ surface: IOSurface) {
        layer?.contents = surface
    }

    isolated deinit {
        displayLink?.invalidate()
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
