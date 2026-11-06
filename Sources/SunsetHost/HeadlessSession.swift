public import SunsetCore

/// A terminal with a program running in it, no window: the program's output goes through the parser into the screen, the terminal's replies go back to
/// the program, and keys, pastes and resizes go in. The headless API of the white paper (section 9) and the harness other tests and probes drive.
public final class HeadlessSession {
    public private(set) var terminal: Terminal
    public let process: PTYProcess
    public private(set) var isClosed = false
    private var buffer = [UInt8](repeating: 0, count: 64 * 1024)

    public init(
        _ command: [String],
        columns: Int = 80,
        rows: Int = 24,
        environment: [String: String] = [:],
        directory: String? = nil
    ) throws {
        terminal = Terminal(columns: columns, rows: rows)
        process = try PTYProcess.spawn(
            command,
            environment: environment,
            columns: columns,
            rows: rows,
            directory: directory
        )
    }

    /// Reads what the program has written (waiting up to `timeoutMilliseconds` for the first bytes), feeds it to the terminal and writes the replies
    /// back. Returns false once the program has closed its output.
    @discardableResult public func pump(timeoutMilliseconds: Int = 50) -> Bool {
        guard !isClosed else { return false }
        switch process.read(into: &buffer, timeoutMilliseconds: timeoutMilliseconds) {
            case .data(let count):
                buffer.withUnsafeBufferPointer { terminal.feed($0.span.extracting(0 ..< count)) }
                let replies = terminal.takeReplies()
                if !replies.isEmpty { try? process.write(replies) }
                return true
            case .timeout:
                return true
            case .closed:
                isClosed = true
                return false
        }
    }

    /// Pumps until `condition` holds on the terminal or `timeoutMilliseconds` have passed; true if the condition held.
    public func wait(timeoutMilliseconds: Int = 5000, until condition: (Terminal) -> Bool) -> Bool {
        let deadline = ContinuousClock.now + .milliseconds(timeoutMilliseconds)
        while true {
            if condition(terminal) { return true }
            if ContinuousClock.now >= deadline || isClosed { return condition(terminal) }
            pump(timeoutMilliseconds: 20)
        }
    }

    /// Pumps until the program has closed its output (it exited) or the time is up.
    public func waitForExit(timeoutMilliseconds: Int = 5000) -> Bool {
        let deadline = ContinuousClock.now + .milliseconds(timeoutMilliseconds)
        while !isClosed, ContinuousClock.now < deadline { pump(timeoutMilliseconds: 20) }
        return isClosed
    }

    public func send(_ text: String) throws { try process.write(Array(text.utf8)) }

    public func resize(columns: Int, rows: Int) {
        terminal.resize(columns: columns, rows: rows)
        process.resize(columns: columns, rows: rows)
    }

    /// Marks every row of the screen drawn (a renderer has taken what it needed).
    public func clearDirty() { terminal.clearDirty() }

    /// The screen as lines of text (trailing spaces trimmed).
    public var lines: [String] { (0 ..< terminal.screen.rows).map { terminal.screen.text(row: $0) } }
}
