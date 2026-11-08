public import SunsetCore
internal import Synchronization

/// A program running in a terminal, owned by an actor: the output is read as it arrives (the reader pulls, so the child is slowed by the kernel's buffer
/// and not by our memory), parsed into the screen, the terminal's replies are written back, and a frame consumer is told that something changed.
///
/// The frame consumer *pulls*: `takeSnapshot()` returns a copy of the screen and passes the ownership of the dirty marks to it, so a renderer that asks
/// once per display frame sees exactly what changed since the frame before, however many reads there were between (a fast flood costs one frame, not
/// many; nothing is lost; nothing is drawn that was overwritten). The copy is cheap (the grid is shared until the next write).
public actor TerminalSession {
    public enum Update: Sendable, Equatable {
        /// The screen (or the title, or the modes) changed since the last snapshot.
        case changed
        /// The program has closed its output (it exited); `status` is its exit status when known.
        case closed(status: Int32?)
    }

    public nonisolated let process: PTYProcess
    /// What happened, newest first when the consumer is slow: only the latest update is kept.
    public nonisolated let updates: AsyncStream<Update>
    private let continuation: AsyncStream<Update>.Continuation
    /// What the program asked the host to do (clipboard, notifications; ADR-0010), in order. The host applies its policy; a consumer that falls behind loses
    /// the oldest.
    public nonisolated let hostEvents: AsyncStream<HostEvent>
    private let hostContinuation: AsyncStream<HostEvent>.Continuation
    private let core: SessionCore
    private var reading: Task<Void, Never>?
    public private(set) var isClosed = false

    public init(
        _ command: [String],
        columns: Int = 80,
        rows: Int = 24,
        environment: [String: String] = [:],
        directory: String? = nil,
        scrollbackLimit: Int = 10_000
    ) throws {
        core = SessionCore(Terminal(columns: columns, rows: rows, scrollbackLimit: scrollbackLimit))
        process = try PTYProcess.spawn(
            command,
            environment: environment,
            columns: columns,
            rows: rows,
            directory: directory
        )
        (updates, continuation) = AsyncStream.makeStream(of: Update.self, bufferingPolicy: .bufferingNewest(1))
        (hostEvents, hostContinuation) = AsyncStream.makeStream(
            of: HostEvent.self,
            bufferingPolicy: .bufferingNewest(64)
        )
    }

    /// Starts reading the program's output. Call once.
    public func start() {
        guard reading == nil else { return }
        let (process, core, updates, events) = (process, core, continuation, hostContinuation)
        // On the reader thread, not on this actor: the thread that reads also parses (see `OutputPump`), and tells the consumer once per snapshot.
        reading = Task.detached(executorPreference: process.readThread) { [self] in
            process.pump.run { piece in
                let (replies, hostEvents) = core.ingest(piece)
                if !replies.isEmpty { process.send(replies) }
                for event in hostEvents { events.yield(event) }
                if !core.announced.exchange(true, ordering: .acquiringAndReleasing) { updates.yield(.changed) }
            }
            await finish()
        }
    }

    private func finish() async {
        isClosed = true
        let status = await process.exitStatus(waitingUpTo: 2000)
        continuation.yield(.closed(status: status))
        continuation.finish()
        hostContinuation.finish()
    }

    /// A copy of the screen as it is now; the dirty marks are the changes since the last snapshot, and the live screen's are cleared (see above).
    public func takeSnapshot() -> Screen {
        core.announced.store(false, ordering: .releasing)
        return core.terminal.withLock { terminal in
            let screen = terminal.screen
            terminal.clearDirty()
            return screen
        }
    }

    /// The program in front on the terminal (not the shell itself): see `PTYProcess.foregroundCommandName()`.
    public nonisolated func foregroundCommand() -> String? { process.foregroundCommandName() }

    /// Packs the old lines of the history, at most `limit` chunks of 128 lines (the terminal is locked for that long only: pack in small steps, never while
    /// output is arriving). Returns how many were packed; 0 when there is nothing more. Lines read back as they were.
    @discardableResult
    public nonisolated func packHistory(keepingRecent: Int, limit: Int) -> Int {
        core.terminal.withLock {
            $0.packHistory(using: LZFSEHistoryCodec(), keepingRecent: keepingRecent, limit: limit)
        }
    }

    /// A copy of the screen as it is, without the dirty marks being cleared (`takeSnapshot` clears them for the renderer): for a copy that is kept to read (the
    /// window's selection) to take the history that was packed in the meantime (`Screen.adoptHistory`).
    public nonisolated func screenCopy() -> Screen { core.terminal.withLock { $0.screen } }

    /// Frees the cells that reading packed lines decoded (they are decoded again when read).
    public nonisolated func releaseDecodedHistory() { core.terminal.withLock { $0.screen.releaseDecodedHistory() } }

    public nonisolated func historyFootprint() -> HistoryFootprint {
        core.terminal.withLock { $0.screen.historyFootprint }
    }

    /// Sends bytes to the program, in order with everything else sent.
    public func send(_ bytes: [UInt8]) { process.send(bytes) }

    /// Sends a key, encoded for the modes the program has set *now* (application cursor keys, the keyboard protocol's flags).
    public func send(_ press: KeyPress) {
        let (modes, flags) = core.terminal.withLock { ($0.screen.modes, $0.screen.keyboardFlags) }
        process.send(KeyEncoder.encode(press, modes: modes, keyboardFlags: flags))
    }

    /// Sends a mouse event as the program asked for it. Returns whether the program has it (tracking on, even if this event is one it does not want; or the
    /// wheel on the alternate screen with alternate scroll on, which becomes the arrow keys): false means the window can use the event itself (select, scroll
    /// the history).
    @discardableResult
    public func send(_ event: MouseEvent) -> Bool {
        let screen = core.terminal.withLock { $0.screen }
        let modes = screen.modes
        guard modes.mouseTracking != .none else {
            guard screen.isAlternate, modes.alternateScroll, event.action == .press else { return false }
            switch event.button {
                case .wheelUp: send(KeyPress(.up))
                case .wheelDown: send(KeyPress(.down))
                default: return false
            }
            return true
        }
        if let bytes = MouseEncoder.encode(event, tracking: modes.mouseTracking, format: modes.mouseFormat) {
            process.send(bytes)
        }
        return true
    }

    /// Sends typed text (composed by the input system) as the program should read it.
    public func send(text: String) { process.send(Array(text.utf8)) }

    /// Sends a paste: bracketed when the program asked for that.
    public func paste(_ text: String) {
        process.send(PasteEncoder.encode(text, bracketed: core.terminal.withLock { $0.screen.modes.bracketedPaste }))
    }

    /// The theme's default colours (nil leaves one as it is); the screen is drawn again.
    public func setDefaultColors(foreground: RGB?, background: RGB?, cursor: RGB?) {
        core.terminal.withLock { $0.setDefaultColors(foreground: foreground, background: background, cursor: cursor) }
        continuation.yield(.changed)
    }

    /// The theme's 16 ANSI colours; the screen is drawn again.
    public func setAnsiColors(_ colors: [RGB]) {
        core.terminal.withLock { $0.setAnsiColors(colors) }
        continuation.yield(.changed)
    }

    public func resize(columns: Int, rows: Int) {
        core.terminal.withLock { $0.resize(columns: columns, rows: rows) }
        process.resize(columns: columns, rows: rows)
        continuation.yield(.changed)
    }

    /// Stops reading and asks the program to end (it receives SIGHUP when the session goes away).
    public func stop() {
        reading?.cancel()
        process.pump.stop()
        process.hangUp()
    }
}
