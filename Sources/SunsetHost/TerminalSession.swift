public import SunsetCore

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
    private var terminal: Terminal
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
        terminal = Terminal(columns: columns, rows: rows, scrollbackLimit: scrollbackLimit)
        process = try PTYProcess.spawn(
            command,
            environment: environment,
            columns: columns,
            rows: rows,
            directory: directory
        )
        (updates, continuation) = AsyncStream.makeStream(of: Update.self, bufferingPolicy: .bufferingNewest(1))
    }

    /// Starts reading the program's output. Call once.
    public func start() {
        guard reading == nil else { return }
        reading = Task { [process] in
            while !Task.isCancelled, let bytes = await process.read() { ingest(bytes) }
            await finish()
        }
    }

    private func ingest(_ bytes: [UInt8]) {
        bytes.withUnsafeBufferPointer { terminal.feed($0.span) }
        let replies = terminal.takeReplies()
        if !replies.isEmpty { process.send(replies) }
        continuation.yield(.changed)
    }

    private func finish() async {
        isClosed = true
        let status = await process.exitStatus(waitingUpTo: 2000)
        continuation.yield(.closed(status: status))
        continuation.finish()
    }

    /// A copy of the screen as it is now; the dirty marks are the changes since the last snapshot, and the live screen's are cleared (see above).
    public func takeSnapshot() -> Screen {
        let screen = terminal.screen
        terminal.clearDirty()
        return screen
    }

    /// Sends bytes to the program, in order with everything else sent.
    public func send(_ bytes: [UInt8]) { process.send(bytes) }

    /// Sends a key, encoded for the modes the program has set *now* (application cursor keys, the keyboard protocol's flags).
    public func send(_ press: KeyPress) {
        process.send(
            KeyEncoder.encode(press, modes: terminal.screen.modes, keyboardFlags: terminal.screen.keyboardFlags)
        )
    }

    /// Sends a mouse event as the program asked for it. Returns whether the program has the mouse (tracking on, even if this event is one it does not want):
    /// false means the window can use the event itself (select, scroll).
    @discardableResult
    public func send(_ event: MouseEvent) -> Bool {
        let modes = terminal.screen.modes
        guard let bytes = MouseEncoder.encode(event, tracking: modes.mouseTracking, format: modes.mouseFormat) else {
            return false
        }
        process.send(bytes)
        return true
    }

    /// Sends typed text (composed by the input system) as the program should read it.
    public func send(text: String) { process.send(Array(text.utf8)) }

    /// Sends a paste: bracketed when the program asked for that.
    public func paste(_ text: String) {
        process.send(PasteEncoder.encode(text, bracketed: terminal.screen.modes.bracketedPaste))
    }

    public func resize(columns: Int, rows: Int) {
        terminal.resize(columns: columns, rows: rows)
        process.resize(columns: columns, rows: rows)
        continuation.yield(.changed)
    }

    /// Stops reading and asks the program to end (it receives SIGHUP when the session goes away).
    public func stop() {
        reading?.cancel()
        process.hangUp()
    }
}
