import AppKit
import SunsetCore
import SunsetHost
import SunsetRender
import SunsetRenderMac

/// The terminal in a window: a program in a headless session, drawn by the CPU renderer into a layer, with keys and pastes going the other way. Frames are
/// drawn at the display's pace and only when something changed (the display link is paused otherwise: an idle terminal wakes nothing).
final class TerminalView: NSView {
    private let session: HeadlessSession
    private var glyphs: CoreTextGlyphSource
    private var renderer: CPURenderer
    private var surface: Surface
    private let fontName: String
    private let fontSize: Double
    private let features: [FontFeature]
    private let ligatures: Bool
    private var scale: CGFloat = 2
    private var readSource: DispatchSourceRead?
    private var displayLink: CADisplayLink?
    private var blinkTimer: Timer?
    private var cursorPhase = true
    private var lastTitle = ""
    var onTitle: ((String) -> Void)?
    var onExit: (() -> Void)?

    init(
        command: [String],
        environment: [String: String],
        fontName: String,
        fontSize: Double,
        features: [FontFeature],
        ligatures: Bool
    ) throws {
        self.fontName = fontName
        self.fontSize = fontSize
        self.features = features
        self.ligatures = ligatures
        let glyphs = CoreTextGlyphSource(fontName: fontName, size: fontSize * 2, features: features)
        self.glyphs = glyphs
        renderer = CPURenderer(metrics: glyphs.metrics, glyphs: glyphs, ligatures: ligatures)
        session = try HeadlessSession(command, columns: 80, rows: 24, environment: environment)
        surface = Surface(width: 1, height: 1)
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 500))
        wantsLayer = true
        layer?.contentsGravity = .topLeft
        layer?.isOpaque = true
        startReading()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in self?.blink() }
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    // MARK: Layout

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        displayLink = displayLink(target: self, selector: #selector(frameTick))
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.isPaused = true
        applyScale()
        resizeGrid()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        applyScale()
        resizeGrid()
    }

    override func layout() {
        super.layout()
        resizeGrid()
    }

    /// Cell metrics are in device pixels: the font is rasterised at the backing scale.
    private func applyScale() {
        let newScale = window?.backingScaleFactor ?? 2
        guard newScale != scale || glyphs.metrics.cellWidth == 0 else { return }
        scale = newScale
        layer?.contentsScale = newScale
        let made = CoreTextGlyphSource(fontName: fontName, size: fontSize * Double(newScale), features: features)
        glyphs = made
        renderer = CPURenderer(metrics: made.metrics, glyphs: made, ligatures: ligatures)
    }

    private func resizeGrid() {
        let metrics = glyphs.metrics
        let pixelWidth = Int(bounds.width * scale)
        let pixelHeight = Int(bounds.height * scale)
        let columns = max(2, (pixelWidth - 2 * 8) / metrics.cellWidth)
        let rows = max(1, (pixelHeight - 2 * 8) / metrics.cellHeight)
        guard columns != session.terminal.screen.columns || rows != session.terminal.screen.rows || surface.width <= 1
        else { return }
        session.resize(columns: columns, rows: rows)
        var padded = metrics
        padded.paddingX = 8
        padded.paddingY = 8
        let size = padded.surfaceSize(columns: columns, rows: rows)
        surface = Surface(width: size.width, height: size.height)
        renderer = CPURenderer(metrics: padded, glyphs: glyphs, ligatures: ligatures)
        scheduleFrame()
    }

    // MARK: Output

    private func startReading() {
        let source = DispatchSource.makeReadSource(fileDescriptor: session.process.fileDescriptor, queue: .main)
        source.setEventHandler { [weak self] in self?.readable() }
        source.resume()
        readSource = source
    }

    private func readable() {
        // Everything that is there, up to a bound, so that a flood of output cannot starve the run loop (the next event picks up the rest).
        var rounds = 0
        while rounds < 32, session.pump(timeoutMilliseconds: 0) { rounds += 1 }
        if session.isClosed {
            readSource?.cancel()
            onExit?()
            return
        }
        scheduleFrame()
    }

    private func scheduleFrame() { displayLink?.isPaused = false }

    @objc private func frameTick() {
        displayLink?.isPaused = true
        guard surface.width > 1 else { return }
        renderer.render(
            session.terminal.screen,
            into: &surface,
            cursorVisible: cursorPhase || !session.terminal.screen.cursorBlinks
        )
        session.clearDirty()
        layer?.contents = makeImage()
        let title = session.terminal.screen.title
        if title != lastTitle {
            lastTitle = title
            onTitle?(title)
        }
    }

    private func blink() {
        guard session.terminal.screen.cursorBlinks, window?.isKeyWindow == true else {
            if !cursorPhase {
                cursorPhase = true
                scheduleFrame()
            }
            return
        }
        cursorPhase.toggle()
        scheduleFrame()
    }

    private func makeImage() -> CGImage? {
        let bytes = Data(surface.rgbaBytes)
        guard let provider = CGDataProvider(data: bytes as CFData) else { return nil }
        return CGImage(
            width: surface.width,
            height: surface.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: surface.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    // MARK: Input

    override func keyDown(with event: NSEvent) {
        guard let press = keyPress(from: event) else { return }
        cursorPhase = true
        let bytes = KeyEncoder.encode(
            press,
            modes: session.terminal.screen.modes,
            keyboardFlags: session.terminal.screen.keyboardFlags
        )
        if !bytes.isEmpty { try? session.process.write(bytes) }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "v" else { return false }
        paste(nil)
        return true
    }

    @objc func paste(_ sender: Any?) {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        let bytes = PasteEncoder.encode(text, bracketed: session.terminal.screen.modes.bracketedPaste)
        try? session.process.write(bytes)
    }

    private func keyPress(from event: NSEvent) -> KeyPress? {
        var modifiers: InputModifiers = []
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.command) { return nil }
        let code: KeyCode
        switch event.keyCode {
            case 36, 76: code = .enter
            case 48: code = .tab
            case 51: code = .backspace
            case 53: code = .escape
            case 126: code = .up
            case 125: code = .down
            case 123: code = .left
            case 124: code = .right
            case 115: code = .home
            case 119: code = .end
            case 116: code = .pageUp
            case 121: code = .pageDown
            case 114: code = .insert
            case 117: code = .delete
            case 122: code = .function(1)
            case 120: code = .function(2)
            case 99: code = .function(3)
            case 118: code = .function(4)
            case 96: code = .function(5)
            case 97: code = .function(6)
            case 98: code = .function(7)
            case 100: code = .function(8)
            case 101: code = .function(9)
            case 109: code = .function(10)
            case 103: code = .function(11)
            case 111: code = .function(12)
            default:
                // Option as Meta: the character the key is, not what Option makes of it.
                let base = event.charactersIgnoringModifiers ?? ""
                guard let scalar = base.unicodeScalars.first else { return nil }
                let text = modifiers.contains(.option) ? base : event.characters
                return KeyPress(.character(scalar), modifiers: modifiers, text: text)
        }
        return KeyPress(code, modifiers: modifiers)
    }
}
