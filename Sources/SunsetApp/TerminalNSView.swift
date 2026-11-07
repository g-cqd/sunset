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

    init(model: TerminalModel) {
        self.model = model
        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        layer?.contentsGravity = .topLeft
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
        displayLink?.invalidate()
        guard window != nil else { return }
        window?.makeFirstResponder(self)
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

    isolated deinit { displayLink?.invalidate() }
}
