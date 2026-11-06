internal import Darwin
internal import Synchronization

/// A child process on a pseudo-terminal: the platform seam of the host (white paper section 9; the core imports none of this). The child is the leader of a
/// session of its own with the slave as its controlling terminal; `resize` sets the window size, which the kernel reports to the foreground group as
/// SIGWINCH. Reads and writes for concurrent callers (`read()`, `send(_:)`) run on threads of their own, never on the cooperative pool and with no Dispatch.
public final class PTYProcess: Sendable {
    public let processID: Int32
    let master: Int32
    let reaped = Mutex(false)
    let readThread = DedicatedThread.start()
    let writeThread = DedicatedThread.start()
    let outbox: AsyncStream<[UInt8]>.Continuation
    let counters = Counters()
    /// Reads the output continuously on `readThread` (the way `TerminalSession` reads; `read()` is the pull for tools and tests).
    let pump: OutputPump
    /// A pipe that wakes the waiting reader when its task is cancelled (the reader waits with no timeout; -1 when the pipe could not be made, and it then falls back
    /// to waking every 50 ms to look).
    let cancelRead: Int32
    let cancelWrite: Int32

    /// Bytes waiting to be written and sends dropped: shared with the writer task.
    final class Counters: Sendable {
        let queued = Mutex(0)
        let dropped = Mutex(0)
        let readWakeups = Mutex(0)
    }

    /// The most input kept waiting for a child that is not reading it (a paste into a stuck program must not grow memory without bound).
    public static let pendingWriteLimit = 1 << 20

    /// The most output kept waiting for the consumer before the reader stops reading (and the child is slowed by the kernel's buffer).
    static let outputBacklogLimit = 1 << 20

    init(master: Int32, processID: Int32) {
        self.master = master
        self.processID = processID
        var ends: [Int32] = [-1, -1]
        if pipe(&ends) == 0 {
            for end in ends {
                _ = fcntl(end, F_SETFL, fcntl(end, F_GETFL) | O_NONBLOCK)
                _ = fcntl(end, F_SETFD, FD_CLOEXEC)
            }
        } else {
            ends = [-1, -1]
        }
        (cancelRead, cancelWrite) = (ends[0], ends[1])
        pump = OutputPump(master: master, thread: readThread, limit: Self.outputBacklogLimit)
        let (stream, continuation) = AsyncStream.makeStream(of: [UInt8].self, bufferingPolicy: .unbounded)
        outbox = continuation
        let fileDescriptor = master
        let counters = counters
        // One writer, in order, on its own thread: a child that is not reading blocks that thread and nothing else.
        Task(executorPreference: writeThread) {
            for await chunk in stream {
                _ = try? PTYProcess.write(chunk, to: fileDescriptor)
                counters.queued.withLock { $0 -= chunk.count }
            }
        }
    }

    deinit {
        outbox.finish()
        pump.stop()
        readThread.stop()
        writeThread.stop()
        close(master)
        if cancelRead >= 0 { close(cancelRead) }
        if cancelWrite >= 0 { close(cancelWrite) }
        if !reaped.withLock({ $0 }) {
            kill(processID, SIGHUP)
            var status: Int32 = 0
            _ = unsafe waitpid(processID, &status, WNOHANG)
        }
    }

    /// How many times the thread that waits for output has woken up: a program that prints nothing must not wake it (an idle terminal costs wakeups).
    public var readWakeups: Int { counters.readWakeups.withLock { $0 } }

    /// The master side of the pseudo-terminal, for a host that waits for output with its own event source (read it only through `read`).
    public var fileDescriptor: Int32 { master }

    // MARK: Control

    public func resize(columns: Int, rows: Int) {
        var size = winsize(
            ws_row: UInt16(clamping: rows),
            ws_col: UInt16(clamping: columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        _ = unsafe ioctl(master, TIOCSWINSZ, &size)
    }

    public func signal(_ number: Int32) { kill(processID, number) }

    /// Asks the child to end, as closing a terminal window does (SIGHUP).
    public func hangUp() { kill(processID, SIGHUP) }

    /// The exit status, waiting up to `milliseconds` for the child to have ended (blocking: for tools and tests; sessions use `exitStatus(waitingUpTo:)`
    /// from async code).
    public func exitStatusBlocking(waitingUpTo milliseconds: Int) -> Int32? {
        var waited = 0
        while true {
            if let status = exitStatus() { return status }
            if waited >= milliseconds { return nil }
            _ = poll(nil, 0, 5)
            waited += 5
        }
    }

    /// The exit status, waiting up to `milliseconds` on a thread of its own (so the caller's executor is not held).
    public func exitStatus(waitingUpTo milliseconds: Int) async -> Int32? {
        await Task(executorPreference: readThread) { self.exitStatusBlocking(waitingUpTo: milliseconds) }.value
    }

    /// The exit status if the child has ended (reaping it), nil while it runs.
    public func exitStatus() -> Int32? {
        reaped.withLock { done in
            guard !done else { return 0 }
            var status: Int32 = 0
            let result = unsafe waitpid(processID, &status, WNOHANG)
            guard result == processID else { return nil }
            done = true
            // WIFEXITED / WEXITSTATUS / WIFSIGNALED as the macros define them.
            if status & 0x7F == 0 { return (status >> 8) & 0xFF }
            return 128 + (status & 0x7F)
        }
    }
}
