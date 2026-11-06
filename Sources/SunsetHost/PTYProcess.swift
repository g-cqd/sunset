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

    /// Bytes waiting to be written and sends dropped: shared with the writer task.
    final class Counters: Sendable {
        let queued = Mutex(0)
        let dropped = Mutex(0)
    }

    /// The most input kept waiting for a child that is not reading it (a paste into a stuck program must not grow memory without bound).
    public static let pendingWriteLimit = 1 << 20

    init(master: Int32, processID: Int32) {
        self.master = master
        self.processID = processID
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
        readThread.stop()
        writeThread.stop()
        close(master)
        if !reaped.withLock({ $0 }) {
            kill(processID, SIGHUP)
            var status: Int32 = 0
            _ = unsafe waitpid(processID, &status, WNOHANG)
        }
    }

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
