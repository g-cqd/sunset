import IOSurface
import Observation
import SunsetConfig
import SunsetCore
import SunsetHost
import SunsetRender
import SunsetRenderMac

/// The state of one terminal window: the program (a `TerminalSession` actor), the renderer (a `FrameRenderer` actor) and what the window shows. It lives on
/// the main actor; the reading, parsing and drawing happen on the two actors, and only values cross: snapshots of the screen one way, finished frames
/// the other. Frames are pulled at the display's pace (the display link asks, `tick()` answers) and only while something changed.
@MainActor @Observable final class TerminalModel {
    private(set) var title = "Sunset"
    /// The working directory the program reported (OSC 7) and its progress (OSC 9;4), 0 to 1: what a tab can show next to its title.
    private(set) var directory: String?
    private(set) var progress: Double?
    /// The program in front on the terminal when it is not the shell (`TabGlyph` turns it into the command mark).
    var foregroundCommand: String?
    @ObservationIgnored var foregroundCheck: Task<Void, Never>?
    private(set) var isRunning = true
    /// Whether text is selected (observed, so that the Copy menu item follows it).
    var hasSelection = false
    @ObservationIgnored var presentFrame: (IOSurface) -> Void = { _ in }
    /// Keeps the frames in `IOSurface`s the window's layer shows (no image is made and converted on the CPU for each frame).
    @ObservationIgnored let presenter = IOSurfacePresenter()
    @ObservationIgnored var setDisplayLinkPaused: (Bool) -> Void = { _ in }
    @ObservationIgnored var onExit: () -> Void = {}
    /// The directory the program starts in (a restored tab); nil: the user's home.
    @ObservationIgnored var startDirectory: String?
    @ObservationIgnored var session: TerminalSession?
    @ObservationIgnored var renderer: FrameRenderer?
    @ObservationIgnored var scale = 2.0
    @ObservationIgnored var font = FontSettings()
    @ObservationIgnored private var frameWanted = false
    @ObservationIgnored private var renderInFlight = false
    @ObservationIgnored var cursorPhase = true
    @ObservationIgnored var cursorBlinks = true
    @ObservationIgnored var viewPixels = (width: 0, height: 0)
    @ObservationIgnored var viewport = Viewport()
    @ObservationIgnored var selection: Selection?
    @ObservationIgnored var gesture: SelectionGesture?
    @ObservationIgnored var lastScreen: Screen?
    /// The link under the pointer (an id into the last screen's link table), drawn underlined; 0 for none.
    @ObservationIgnored var scrollbackLimit = 10_000
    @ObservationIgnored var blinkSchedule = BlinkSchedule()
    /// The theme's default colours (the configuration file's), applied to the terminal when it starts and whenever they change.
    @ObservationIgnored var defaultColors = DefaultColors()
    /// Space above the grid in points (the strip that drags a window with no title bar).
    @ObservationIgnored var topInsetPoints = 0.0
    /// Trackpad and wheel sensitivity and the wheel's inertia (the configuration's `scroll` section).
    @ObservationIgnored var scroll = Configuration.Scroll()
    @ObservationIgnored var holdsResize = false
    /// When something last happened (a key, or output): the cursor stops blinking a while after.
    @ObservationIgnored var lastActivity = ContinuousClock.now
    /// The window is the key window (so the cursor blinks) and is on screen (so frames are drawn). Set by the view from the window's notifications.
    @ObservationIgnored var hasFocus = true
    @ObservationIgnored var isVisible = true
    /// What the window and the tabs say about this terminal; `hasFocus` and `isVisible` need both.
    @ObservationIgnored var gates = TerminalGates()
    /// The view took the keyboard (a click): the tabs focus this pane.
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    /// Wakes the blink task when it has no timer to wait on (the cursor is solid): activity or the focus coming back.
    @ObservationIgnored let blinkWake = AsyncStream<Void>
        .makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
    @ObservationIgnored var hoveredLink: UInt16 = 0
    /// Whether the program asked for the mouse (as of the last frame): its events go to it, not to the selection.
    var programHasMouse: Bool { (lastScreen?.modes.mouseTracking ?? .none) != .none }
    @ObservationIgnored var lastMotionCell: (column: Int, row: Int)?
    @ObservationIgnored let input = AsyncStream.makeStream(of: InputEvent.self)
    @ObservationIgnored private let sizes = AsyncStream.makeStream(
        of: GridSize.self,
        bufferingPolicy: .bufferingNewest(1)
    )
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    /// Packs the old history while the terminal is quiet (`HistoryPacker`).
    @ObservationIgnored var packer: HistoryPacker?
    @ObservationIgnored private var pending: (command: [String], environment: [String: String])?

    /// Space around the grid in points (the window's padding, or the sidebar's while the sidebar is shown).
    @ObservationIgnored var paddingPoints = 0.0
    /// How opaque the default background is, 0 to 255 (255 with an opaque window).
    @ObservationIgnored var backgroundAlpha: UInt8 = 255

    var paddingPixels: Int { Int((paddingPoints * scale).rounded()) }

    /// Remembers what to run; the program starts when the view first has a size, so that it never sees a window of the wrong size (a shell that draws its
    /// prompt in a 2-column terminal and is then resized leaves a mess behind).
    func start(command: [String], environment: [String: String], font: FontSettings, scrollback: Int? = nil) {
        guard session == nil, pending == nil else { return }
        self.font = font
        pending = (command, environment)
        scrollbackLimit = scrollback ?? 10_000
        makeRenderer()
        startIfReady()
    }

    private func startIfReady() {
        guard session == nil, let (command, inherited) = pending, let size = currentGrid() else { return }
        pending = nil
        var environment = inherited
        // A shell trusts `$PWD` when it names its working directory: the inherited one would take it back to where the app was started.
        if let startDirectory { environment["PWD"] = startDirectory }
        do {
            let session = try TerminalSession(
                command,
                columns: size.columns,
                rows: size.rows,
                environment: environment,
                directory: startDirectory,
                scrollbackLimit: scrollbackLimit
            )
            self.session = session
            packer = HistoryPacker(session) { [weak self] screen in self?.lastScreen?.adoptHistory(from: screen) }
            tasks = [
                Task { [colors = defaultColors] in
                    await colors.apply(to: session)
                    await session.start()
                },
                Task { [weak self] in await self?.watch(session) },
                Task { [weak self] in await self?.watchHostEvents(session) },
                Task { [weak self, events = input.stream] in
                    await Self.forward(events, to: session) { self?.unclaimed($0) }
                },
                Task { [sizes = sizes.stream] in
                    for await size in sizes { await session.resize(columns: size.columns, rows: size.rows) }
                },
                Task { [weak self] in await self?.blink() }
            ]
        } catch {
            title = "Sunset: cannot start \(command.first ?? "the program")"
            isRunning = false
        }
    }

    /// The height of a cell in points (a trackpad scrolls in points).
    var cellHeightInPoints: Double { Double(renderer?.cellMetrics.cellHeight ?? 16) / scale }

    func stop() {
        for task in tasks { task.cancel() }
        packer?.stop()
        tasks = []
        input.continuation.finish()
        sizes.continuation.finish()
        if let session { Task { await session.stop() } }
    }

    // MARK: Size and font

    /// The view's size in device pixels changed: the grid is as many whole cells as fit.
    func viewResized(pixelWidth: Int, pixelHeight: Int, scale newScale: Double) {
        if newScale != scale {
            scale = newScale
            makeRenderer()
        }
        viewPixels = (pixelWidth, pixelHeight)
        guard !holdsResize else { return }
        guard let size = currentGrid() else { return }
        if session == nil {
            startIfReady()
        } else {
            sizes.continuation.yield(size)
        }
        requestFrame()
    }

    func makeRenderer() {
        let glyphs = CoreTextGlyphSource(fontName: font.name, size: font.size * scale, features: font.features)
        var metrics = glyphs.metrics
        metrics.paddingX = paddingPixels
        metrics.paddingY = paddingPixels
        metrics.topInset = Int((topInsetPoints * scale).rounded())
        renderer = FrameRenderer(metrics: metrics, glyphs: glyphs, ligatures: font.ligatures)
    }

    // MARK: Frames

    private func watch(_ session: TerminalSession) async {
        for await update in session.updates {
            switch update {
                case .changed:
                    noteActivity()
                    requestFrame()
                case .closed:
                    isRunning = false
                    onExit()
            }
        }
    }

    func requestFrame() {
        frameWanted = true
        setDisplayLinkPaused(false)
    }

    /// The display link fired: draw a frame if one is wanted and none is being drawn; pause the link when there is nothing to draw.
    func tick() {
        guard frameWanted else {
            setDisplayLinkPaused(true)
            return
        }
        guard isVisible else {
            setDisplayLinkPaused(true)
            return
        }
        guard !renderInFlight, let session, let renderer else { return }
        frameWanted = false
        renderInFlight = true
        let phase = cursorPhase
        let alpha = backgroundAlpha
        let presenter = presenter
        Task { [weak self] in
            let snapshot = await session.takeSnapshot()
            self?.viewport.follow(historyCount: snapshot.scrollbackCount)
            self?.lastScreen = snapshot
            let changed = await renderer.present(
                snapshot,
                cursorVisible: phase || !snapshot.cursorBlinks,
                textBlinkVisible: phase,
                view: FrameView(
                    scrolledBack: self?.viewport.scrolledBack ?? 0,
                    selection: self?.selection,
                    hoveredLink: self?.hoveredLink ?? 0,
                    backgroundAlpha: alpha,
                    extraPixels: self?.extraPixels(for: snapshot) ?? (0, 0)
                ),
                to: presenter
            )
            self?.presented(changed: changed, snapshot: snapshot)
        }
    }

    private func presented(changed: Bool, snapshot: Screen) {
        renderInFlight = false
        cursorBlinks = snapshot.cursorBlinks
        let shown = snapshot.title.isEmpty ? "Sunset" : snapshot.title
        if shown != title { title = shown }
        let path = snapshot.workingDirectory?.path
        if path != directory { directory = path }
        let fraction = Self.fraction(of: snapshot.progress)
        if fraction != progress { progress = fraction }
        if changed, let latest = presenter.latest { presentFrame(latest) }
        checkForeground()
        // Something may have changed while this frame was being drawn.
        if frameWanted { setDisplayLinkPaused(false) }
    }
}
